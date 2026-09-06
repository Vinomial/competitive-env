# competitive-env: PATH・関数のセットアップ
#
# ~/.zshrc からは
#   source ~/Github/personal/competitive-programming/competitive-env/competitive-env.zsh
# の1行で読み込む想定。PATH や関数の中身を変更したいときはこのファイルだけ
# 直せばよく、~/.zshrc 側への手動コピーは不要(以前は .zshrc 全体を手動同期
# していたため、変更を反映し忘れて「エラーは出ないが動いていない」状態に
# なることがあった)。

export PATH="$HOME/Github/personal/competitive-programming/competitive-env/sh:$PATH"

# competitive-env: run0/run999 shorthand without wrapper files
# (C++/Python どちらも run が自動判別するため、run0..999 だけで両対応)
command_not_found_handler() {
  if [[ "$1" =~ ^run[0-9]{1,3}$ ]]; then
    run "$@"
    return $?
  fi
  print -u2 "zsh: command not found: $1"
  return 127
}

# competitive-env: `run0` だけは systemd 256+ 同梱の sudo 類似コマンド
# (/usr/bin/run0 -> systemd-run) と名前が衝突し、実在コマンドとして解決される
# ため command_not_found_handler が発火しない。明示的に関数で上書きして
# `run 0` にフォールバックさせる(run1..run999 は同名バイナリが無いので不要)。
run0() { run 0 "$@" }

# competitive-env: mkprob auto-cd
mkprob() {
  local prob=""
  if [ "$#" -ge 2 ]; then
    prob="$2"
  fi
  command mkprob "$@" || return $?
  if [ -n "$prob" ] && [ -d "$prob" ]; then
    cd "$prob" || return $?
  fi
}

# competitive-env: mkcontest auto-cd（最初の問題フォルダへ。通常は a）
mkcontest() {
  local cd_file target exit_status
  cd_file="$(mktemp)"
  MKCONTEST_CD_FILE="$cd_file" command mkcontest "$@"
  exit_status=$?
  target="$(cat "$cd_file" 2>/dev/null)"
  rm -f "$cd_file"
  if [ -n "$target" ] && [ -d "$target" ]; then
    cd "$target" || return $?
  fi
  return $exit_status
}

# competitive-env: next/back でコンテスト内の隣の問題フォルダへ移動
next() {
  local target
  target="$(command next)" || return $?
  cd "$target" || return $?
}

back() {
  local target
  target="$(command back)" || return $?
  cd "$target" || return $?
}
