#!/bin/bash

# io / ioall / pyall.sh で共通の出力比較・サンプル解決・TL 解決ロジック。
# resolve_sample_input は呼び出し元が SAMPLE_DIR を設定している前提。

# --- 色・ステータス表示 -----------------------------------------------
# 端末出力時のみ色を付ける(パイプ/リダイレクト先やNO_COLOR指定時は無色のまま)。
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    C_GREEN=$'\033[1;32m'
    C_RED=$'\033[1;31m'
    C_YELLOW=$'\033[1;33m'
    C_CYAN=$'\033[1;36m'
    C_MAGENTA=$'\033[1;35m'
    C_BOLD=$'\033[1m'
    C_DIM=$'\033[2m'
    C_RESET=$'\033[0m'
else
    C_GREEN=""; C_RED=""; C_YELLOW=""; C_CYAN=""; C_MAGENTA=""; C_BOLD=""; C_DIM=""; C_RESET=""
fi

# ステータスタグ([AC] 等)を色付きで出力する。パディング幅は呼び出し側の
# 既存の見た目(タグ直後のスペース数)をそのまま維持するため、タグと
# 残りの文字列を別引数で受け取り呼び出し側で結合できるようにする。
status_color() {
    case "$1" in
        AC|OK|DEBUG-OK|TRACE-OK)
            echo "$C_GREEN" ;;
        WA|RE|MISMATCH|DEBUG-RE|TRACE-RE|GEN-ERROR|BRUTE-ERROR)
            echo "$C_RED" ;;
        TLE)
            echo "$C_YELLOW" ;;
        RUN)
            echo "$C_CYAN" ;;
        *)
            echo "$C_RESET" ;;
    esac
}

# "[TAG]" 部分だけ色付けした文字列を返す(前後の空白はそのまま呼び出し側で付与する)。
colored_tag() {
    local tag="$1"
    local color
    color="$(status_color "$tag")"
    printf '%s[%s]%s' "$color" "$tag" "$C_RESET"
}

# expected/actual(またはbrute/main)を全文表示する際、一致する行は緑、
# 異なる行は赤で色付けして出力する。side="old" なら old_file 側を、
# side="new" なら new_file 側を全文出力する。
print_diff_side() {
    local old_file="$1"
    local new_file="$2"
    local side="$3"

    if [ "$side" = "old" ]; then
        diff --old-line-format="${C_RED}%L${C_RESET}" --new-line-format='' \
             --unchanged-line-format="${C_GREEN}%L${C_RESET}" "$old_file" "$new_file"
    else
        diff --old-line-format='' --new-line-format="${C_RED}%L${C_RESET}" \
             --unchanged-line-format="${C_GREEN}%L${C_RESET}" "$old_file" "$new_file"
    fi
}

# 全サンプル実行時の集計(ioall/pyall.sh の実行結果を最後にまとめて表示するため)。
declare -A STATUS_COUNTS=()

tally_add() {
    local tag="$1"
    STATUS_COUNTS["$tag"]=$(( ${STATUS_COUNTS["$tag"]:-0} + 1 ))
}

# 例: "AC 3  WA 1  (total 4)" を色付きで返す。
tally_summary() {
    local tag n total=0
    local parts=()
    for tag in AC WA RE TLE RUN; do
        n="${STATUS_COUNTS[$tag]:-0}"
        total=$((total + n))
        if [ "$n" -gt 0 ]; then
            parts+=("$(colored_tag "$tag") ${n}")
        fi
    done
    printf '%s  (total %d)\n' "${parts[*]}" "$total"
}

normalize_output() {
    local file="$1"

    LC_ALL=C perl -0777 -pe '
        s/[\t\r ]+(?=\n|\z)//g;
        s/\n*\z//;
        $_ .= "\n" if length;
    ' "$file"
}

outputs_match() {
    local expected="$1"
    local actual="$2"

    if cmp -s "$expected" "$actual"; then
        return 0
    fi

    cmp -s <(normalize_output "$expected") <(normalize_output "$actual")
}

# スペシャルジャッジ対応。カレントディレクトリに checker.cpp/checker.py が
# あればそれをビルド/用意して CHECKER_CMD にセットする(呼び出し元が
# SCRIPT_DIR を設定している前提。stress.sh の gen/brute と同じ命名規則)。
# 無ければ CHECKER_CMD は空のままにする(=judge_matches が通常の exact
# diff にフォールバックする)。checker のビルド失敗はエラーとして返す。
CHECKER_CMD=()

setup_checker() {
    if [ -f "checker.cpp" ]; then
        if ! CPP_OUT="./checker.out" "$SCRIPT_DIR/build.sh" checker >&2; then
            echo "error: checker.cpp のビルドに失敗しました。" >&2
            return 1
        fi
        CHECKER_CMD=(./checker.out)
    elif [ -f "checker.py" ]; then
        CHECKER_CMD=(python3 checker.py)
    fi
    return 0
}

# 正誤判定本体。checker が設定されていればそれを
# `checker <input> <expected> <actual>` (exit 0 = 正解) として呼び、
# 無ければ通常の exact diff (outputs_match) にフォールバックする。
judge_matches() {
    local infile="$1"
    local expected="$2"
    local actual="$3"

    if [ "${#CHECKER_CMD[@]}" -gt 0 ]; then
        "${CHECKER_CMD[@]}" "$infile" "$expected" "$actual"
        return $?
    fi

    outputs_match "$expected" "$actual"
}

resolve_sample_input() {
    local idx="$1"
    if [ ! -d "$SAMPLE_DIR" ]; then
        return 1
    fi

    if [ -f "$SAMPLE_DIR/sample-${idx}.in" ]; then
        echo "$SAMPLE_DIR/sample-${idx}.in"
        return 0
    fi

    local infile base suffix
    for infile in "$SAMPLE_DIR"/*.in; do
        base="$(basename "${infile%.in}")"
        if [[ "$base" =~ -([0-9]+)$ ]]; then
            suffix="${BASH_REMATCH[1]}"
            if [ $((10#$suffix)) -eq $((10#$idx)) ]; then
                echo "$infile"
                return 0
            fi
        fi
    done
    return 1
}

# AtCoder の標準的な制限時間。tl.txt も --tl も無い問題はこれを使う。
# 別の値をデフォルトにしたければ環境変数 DEFAULT_TL_MS で上書きできる。
DEFAULT_TL_MS="${DEFAULT_TL_MS:-2000}"

# 実行時間制限(ms)を解決する。優先順位:
#   1) TL_MS 環境変数(--tl オプションでその場限り指定)
#   2) ./tl.txt (問題ごとに制限時間が違う場合の個別指定)
#   3) DEFAULT_TL_MS (通常は 2000ms)
resolve_time_limit() {
    if [ -n "${TL_MS:-}" ] && [[ "$TL_MS" =~ ^[0-9]+$ ]]; then
        echo "$TL_MS"
        return 0
    fi

    if [ -f "tl.txt" ]; then
        local v
        v="$(tr -dc '0-9' < tl.txt)"
        if [ -n "$v" ]; then
            echo "$v"
            return 0
        fi
    fi

    echo "$DEFAULT_TL_MS"
    return 0
}

# 現在時刻をミリ秒(epoch)で返す。
# GNU date の `date +%s%3N`(秒 + 3桁ミリ秒)に依存していたが、uutils coreutils の
# date は `%3N` の桁幅指定を無視してナノ秒をそのまま出すため、経過時間が約100万倍に
# 膨らんで全ケース TLE 扱いになっていた。桁幅指定なしの `%N` は両実装とも
# ナノ秒9桁を返すので、それを 1e6 で割ってミリ秒にする。
now_ms() {
    local ns
    ns="$(date +%s%N)"
    echo "$((ns / 1000000))"
}
