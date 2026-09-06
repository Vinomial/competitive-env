#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
    echo "usage: stress [--count N] [--seed-start N] [--debug] [--tl ms] [main_source]" >&2
    echo "" >&2
    echo "  カレントディレクトリに以下が必要:" >&2
    echo "    gen.cpp / gen.py   : argv[1] にシード(整数)を受け取り、標準出力にランダムな入力を1件出力" >&2
    echo "    brute.cpp / brute.py : 遅くても良いので確実に正しい参照実装" >&2
    echo "  main_source を省略した場合は run/runall と同じ自動判定(フォルダ名 or 唯一の *.cpp/*.py)" >&2
    exit 1
}

. "$SCRIPT_DIR/resolve_target.sh"
. "$SCRIPT_DIR/io_compare.sh"
setup_checker || exit 1

COUNT=100
SEED_START=1
DEBUG=false
TL=""
SOURCE_ARG=""

while [ $# -gt 0 ]; do
    case "$1" in
        --count)
            shift
            [ $# -gt 0 ] || usage
            COUNT="$1"
            shift
            ;;
        --seed-start)
            shift
            [ $# -gt 0 ] || usage
            SEED_START="$1"
            shift
            ;;
        --debug|-d)
            DEBUG=true
            shift
            ;;
        --tl)
            shift
            [ $# -gt 0 ] || usage
            TL="$1"
            shift
            ;;
        --help|-h)
            usage
            ;;
        *)
            if [ -z "$SOURCE_ARG" ]; then
                SOURCE_ARG="$1"
            else
                usage
            fi
            shift
            ;;
    esac
done

if ! [[ "$COUNT" =~ ^[0-9]+$ ]] || [ "$COUNT" -lt 1 ]; then
    echo "error: --count must be a positive integer." >&2
    exit 1
fi
if ! [[ "$SEED_START" =~ ^[0-9]+$ ]]; then
    echo "error: --seed-start must be a non-negative integer." >&2
    exit 1
fi

# resolve_time_limit() は TL_MS 環境変数を最優先で見るので、--tl の値を渡す。
TL_MS="$TL"

MAIN_TARGET="$(resolve_target "$SOURCE_ARG")" || exit 1
GEN_TARGET="$(resolve_target "gen")" || {
    echo "  argv[1] にシードを受け取り、標準出力にランダム入力を出力するジェネレータを用意してください。" >&2
    exit 1
}
BRUTE_TARGET="$(resolve_target "brute")" || {
    echo "  遅くても確実に正しい参照実装を用意してください。" >&2
    exit 1
}

echo "main:  $MAIN_TARGET"
echo "gen:   $GEN_TARGET"
echo "brute: $BRUTE_TARGET"

if [[ "$MAIN_TARGET" == *.cpp ]]; then
    MAIN_BASE="${MAIN_TARGET%.cpp}"
    if $DEBUG; then
        CPP_OUT="./stress_main.out" "$SCRIPT_DIR/build.sh" "$MAIN_BASE" debug || exit 1
    else
        CPP_OUT="./stress_main.out" "$SCRIPT_DIR/build.sh" "$MAIN_BASE" || exit 1
    fi
    MAIN_CMD=(./stress_main.out)
else
    MAIN_CMD=(python3 "$MAIN_TARGET")
fi

if [[ "$GEN_TARGET" == *.cpp ]]; then
    GEN_BASE="${GEN_TARGET%.cpp}"
    CPP_OUT="./stress_gen.out" "$SCRIPT_DIR/build.sh" "$GEN_BASE" || exit 1
    GEN_CMD=(./stress_gen.out)
else
    GEN_CMD=(python3 "$GEN_TARGET")
fi

if [[ "$BRUTE_TARGET" == *.cpp ]]; then
    BRUTE_BASE="${BRUTE_TARGET%.cpp}"
    CPP_OUT="./stress_brute.out" "$SCRIPT_DIR/build.sh" "$BRUTE_BASE" || exit 1
    BRUTE_CMD=(./stress_brute.out)
else
    BRUTE_CMD=(python3 "$BRUTE_TARGET")
fi

STRESS_FAIL_DIR="stress_fail"
IN_FILE="stress_in.tmp"
MAIN_OUT="stress_main_out.tmp"
MAIN_ERR="stress_main_err.tmp"
BRUTE_OUT="stress_brute_out.tmp"
BRUTE_ERR="stress_brute_err.tmp"

cleanup_tmp() {
    rm -f "$IN_FILE" "$MAIN_OUT" "$MAIN_ERR" "$BRUTE_OUT" "$BRUTE_ERR"
    rm -f ./stress_main.out ./stress_gen.out ./stress_brute.out
    if [ "${#CHECKER_CMD[@]}" -gt 0 ] && [ "${CHECKER_CMD[0]}" = "./checker.out" ]; then
        rm -f ./checker.out
    fi
}

save_failure() {
    local reason="$1"
    mkdir -p "$STRESS_FAIL_DIR"
    cp "$IN_FILE" "$STRESS_FAIL_DIR/in.txt"
    [ -f "$MAIN_OUT" ] && cp "$MAIN_OUT" "$STRESS_FAIL_DIR/main_out.txt"
    [ -f "$MAIN_ERR" ] && cp "$MAIN_ERR" "$STRESS_FAIL_DIR/main_err.txt"
    [ -f "$BRUTE_OUT" ] && cp "$BRUTE_OUT" "$STRESS_FAIL_DIR/brute_out.txt"
    echo "  $reason"
    echo "  再現入力: $STRESS_FAIL_DIR/in.txt"
}

echo "=== stress test: ${COUNT} 件 (seed ${SEED_START} 〜 $((SEED_START + COUNT - 1))) ==="

for ((i = 0; i < COUNT; i++)); do
    seed=$((SEED_START + i))

    if "${GEN_CMD[@]}" "$seed" > "$IN_FILE"; then
        :
    else
        echo "$(colored_tag GEN-ERROR) seed=$seed: generator が異常終了しました。" >&2
        cleanup_tmp
        exit 1
    fi

    : > "$BRUTE_ERR"
    if "${BRUTE_CMD[@]}" < "$IN_FILE" > "$BRUTE_OUT" 2>"$BRUTE_ERR"; then
        brute_status=0
    else
        brute_status=$?
    fi
    if [ "$brute_status" -ne 0 ]; then
        echo "$(colored_tag BRUTE-ERROR) seed=$seed: brute が異常終了しました(exit $brute_status)。" >&2
        if [ -s "$BRUTE_ERR" ]; then
            cat "$BRUTE_ERR" >&2
        fi
        save_failure "brute 自体が異常終了(exit $brute_status): brute の実装を確認してください"
        cleanup_tmp
        exit 1
    fi

    : > "$MAIN_ERR"
    start=$(now_ms)
    if "${MAIN_CMD[@]}" < "$IN_FILE" > "$MAIN_OUT" 2>"$MAIN_ERR"; then
        main_status=0
    else
        main_status=$?
    fi
    end=$(now_ms)
    elapsed=$((end - start))

    if [ "$main_status" -ne 0 ]; then
        echo "$(colored_tag RE)   seed=$seed (${elapsed} ms, exit $main_status)"
        if [ -s "$MAIN_ERR" ]; then
            cat "$MAIN_ERR" >&2
        fi
        save_failure "main が異常終了(exit $main_status)"
        cleanup_tmp
        exit 1
    fi

    tl="$(resolve_time_limit || true)"
    if [ -n "$tl" ] && [ "$elapsed" -gt "$tl" ]; then
        echo "$(colored_tag TLE)  seed=$seed (${elapsed} ms > ${tl} ms)"
        save_failure "main が制限時間を超過(${elapsed} ms > ${tl} ms)"
        cleanup_tmp
        exit 1
    fi

    if judge_matches "$IN_FILE" "$BRUTE_OUT" "$MAIN_OUT"; then
        echo "$(colored_tag OK)   seed=$seed (${elapsed} ms)"
    else
        echo "$(colored_tag MISMATCH) seed=$seed (${elapsed} ms)"
        save_failure "main と brute の出力が不一致"
        echo "  --- brute ---"
        print_diff_side "$BRUTE_OUT" "$MAIN_OUT" old | sed 's/^/  /'
        echo "  --- main ---"
        print_diff_side "$BRUTE_OUT" "$MAIN_OUT" new | sed 's/^/  /'
        cleanup_tmp
        exit 1
    fi
done

cleanup_tmp
echo "${C_GREEN}=== ${COUNT} 件とも一致しました ===${C_RESET}"
