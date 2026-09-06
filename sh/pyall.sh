#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# options
CLEAN=false
SAMPLE_ONLY=""
NAME=""
NO_DIFF=false

while [ $# -gt 0 ]; do
    case "$1" in
        --clean)
            CLEAN=true
            shift
            ;;
        --nodiff)
            NO_DIFF=true
            shift
            ;;
        --sample|--only|-s)
            shift
            [ $# -gt 0 ] || { echo "error: --sample requires a number." >&2; exit 1; }
            SAMPLE_ONLY="$1"
            shift
            ;;
        --tl)
            shift
            [ $# -gt 0 ] || { echo "error: --tl requires a number(ms)." >&2; exit 1; }
            TL_MS="$1"
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            if [ -z "$NAME" ]; then
                NAME="$1"
                shift
            else
                echo "error: unexpected argument: $1" >&2
                exit 1
            fi
            ;;
    esac
done

if [ -z "$NAME" ] && [ $# -gt 0 ]; then
    NAME="$1"
    shift
fi

if [ -n "$SAMPLE_ONLY" ] && ! [[ "$SAMPLE_ONLY" =~ ^[0-9]{1,3}$ ]]; then
    echo "error: sample must be 0..999."
    exit 1
fi

# 対象ファイルの自動判定:
# 1) 引数あり: その名前
# 2) 引数なし: カレントディレクトリ名.py
# 3) それが無ければ *.py が1つだけならそれを使う
if [ -n "$NAME" ]; then
    NAME="${NAME%.py}"
    PY_FILE="$NAME.py"
else
    DIR_NAME="$(basename "$PWD")"
    if [ -f "$DIR_NAME.py" ]; then
        PY_FILE="$DIR_NAME.py"
    else
        shopt -s nullglob
        PY_FILES=( *.py )
        if [ "${#PY_FILES[@]}" -eq 1 ]; then
            PY_FILE="${PY_FILES[0]}"
        elif [ "${#PY_FILES[@]}" -eq 0 ]; then
            echo "error: no target .py found."
            echo "hint: create $DIR_NAME.py or run: pyall <name>"
            exit 1
        else
            echo "error: multiple .py files found."
            echo "hint: run: pyall <name>"
            exit 1
        fi
    fi
fi

SAMPLE_DIR="samples"
FAIL_DIR="failures"

if $CLEAN; then
    rm -rf "$FAIL_DIR"
fi

if [ ! -f "$PY_FILE" ]; then
    echo "error: $PY_FILE not found."
    exit 1
fi

. "$SCRIPT_DIR/io_compare.sh"
setup_checker || exit 1

shopt -s nullglob
OK_ALL=true
SINGLE=false
HAD_TLE=false

run_case() {
    local infile="$1"
    local outfile="$2"
    local label="$3"
    local tmpfile="$4"
    local difffile="$5"

    start=$(now_ms)
    python3 "$PY_FILE" < "$infile" > "$tmpfile"
    end=$(now_ms)
    elapsed=$((end - start))

    if $SINGLE; then
        echo "${C_BOLD}--- input ---${C_RESET}"
        cat "$infile"
        echo "${C_BOLD}--- output ---${C_RESET}"
        cat "$tmpfile"
        echo
    fi

    local tl tle_note=""
    tl="$(resolve_time_limit || true)"
    if [ -n "$tl" ] && [ "$elapsed" -gt "$tl" ]; then
        tle_note=" ${C_YELLOW}[TLE > ${tl} ms]${C_RESET}"
        HAD_TLE=true
    fi

    if [ -f "$outfile" ]; then
        if judge_matches "$infile" "$outfile" "$tmpfile"; then
            if [ -n "$tle_note" ]; then
                echo "$(colored_tag TLE)  $label (${elapsed} ms)${tle_note}"
                tally_add TLE
                OK_ALL=false
            else
                echo "$(colored_tag AC)   $label (${elapsed} ms)"
                tally_add AC
            fi
        else
            echo "$(colored_tag WA)   $label (${elapsed} ms)${tle_note}"
            tally_add WA
            mkdir -p "$FAIL_DIR"
            diff -u --label expected --label actual "$outfile" "$tmpfile" > "$difffile"
            if $SINGLE; then
                echo "${C_BOLD}--- expected ---${C_RESET}"
                print_diff_side "$outfile" "$tmpfile" old
                echo
            elif ! $NO_DIFF; then
                echo "${C_BOLD}--- expected ---${C_RESET}"
                print_diff_side "$outfile" "$tmpfile" old
                echo "${C_BOLD}--- actual ---${C_RESET}"
                print_diff_side "$outfile" "$tmpfile" new
            fi
            OK_ALL=false
        fi
    else
        if [ -n "$tle_note" ]; then
            echo "$(colored_tag TLE)  $label (${elapsed} ms)${tle_note}"
            tally_add TLE
            OK_ALL=false
        else
            echo "$(colored_tag RUN)  $label (${elapsed} ms)"
            tally_add RUN
        fi
        if ! $SINGLE; then
            cat "$tmpfile"
        fi
    fi

    rm -f "$tmpfile"
}

if [ -n "$SAMPLE_ONLY" ]; then
    SINGLE=true
    sample_in="$(resolve_sample_input "$SAMPLE_ONLY" || true)"

    if [ -n "$sample_in" ]; then
        base="$(basename "${sample_in%.in}")"
        outfile="${sample_in%.in}.out"
        tmpfile="$SAMPLE_DIR/$base.tmp"
        difffile="$FAIL_DIR/$base.diff"
        run_case "$sample_in" "$outfile" "$base" "$tmpfile" "$difffile"
    else
        if [ ! -f "./in.txt" ]; then
            echo "error: sample $SAMPLE_ONLY not found and in.txt not found."
            exit 1
        fi
        run_case "in.txt" "out.txt" "in.txt" "in.tmp" "$FAIL_DIR/in.diff"
    fi
else
    if [ ! -d "$SAMPLE_DIR" ]; then
        echo "error: samples directory not found."
        exit 1
    fi

    for infile in "$SAMPLE_DIR"/*.in; do
        base="$(basename "${infile%.in}")"
        outfile="$SAMPLE_DIR/$base.out"
        tmpfile="$SAMPLE_DIR/$base.tmp"
        difffile="$FAIL_DIR/$base.diff"
        run_case "$infile" "$outfile" "$base" "$tmpfile" "$difffile"
    done
fi

if $OK_ALL; then
    if $SINGLE; then
        :
    else
        echo "${C_GREEN}=== 全サンプルAC ===${C_RESET} $(tally_summary)"
        echo "=== コピーします ==="
        if command -v xclip >/dev/null 2>&1; then
            if xclip -selection clipboard < "$PY_FILE"; then
                echo "[Copied] $PY_FILE"
            else
                echo "warning: xclip failed; not copied."
            fi
        else
            echo "warning: xclip not found; not copied."
        fi
        if [ -d "$FAIL_DIR" ]; then
            rm -rf "$FAIL_DIR"
        fi
    fi
else
    if $SINGLE; then
        :
    else
        if $HAD_TLE; then
            echo "${C_YELLOW}=== 一部TLE ===${C_RESET} $(tally_summary)"
        else
            echo "${C_RED}=== 一部WA ===${C_RESET} $(tally_summary)"
        fi
    fi
fi

if $OK_ALL; then
    exit 0
else
    exit 1
fi
