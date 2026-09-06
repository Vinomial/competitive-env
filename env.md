# Shell Environment Summary (`~/.zshrc`)

このファイルは、現在の `~/.zshrc` の有効設定を要約したメモです。

## Base

- Shell framework: Oh My Zsh
- `ZSH="$HOME/.oh-my-zsh"`
- `ZSH_THEME="clean"`
- `plugins=(git)`
- `source $ZSH/oh-my-zsh.sh`

## competitive-env のセットアップ

`~/.zshrc` には以下の1行だけを書く。

```zsh
source "$HOME/Github/personal/competitive-programming/competitive-env/competitive-env.zsh"
```

PATH設定・関数の中身はすべて `competitive-env.zsh`（リポジトリ管理下）に書かれており、
`~/.zshrc` からは `source` されるだけ。**PATHや関数を変更したいときは
`~/.zshrc` ではなく `competitive-env.zsh` を直す**（`~/.zshrc` 側への手動コピーは不要。
以前は `.zshrc` 全体を手動同期する方式だったが、変更の反映を忘れて
「エラーは出ないが動いていない」状態になったことがあったため、この方式に変更した）。

### PATH

- `export PATH="$HOME/Github/personal/competitive-programming/competitive-env/sh:$PATH"`
- これにより `competitive-env/sh` 配下のコマンドが直接実行可能
- ただし `resolve_target.sh` / `io_compare.sh` / `mkprob_core.sh` / `cpp_re_report.sh` /
  `resolve_sibling.sh` は他スクリプトから `source` される内部専用ライブラリで、
  直接コマンドとして呼び出すものではない。`pyall.sh` も `run`/`runall` から
  呼ばれる内部エンジンで、直接使う専用の短縮コマンドは無い
  （C++/Python どちらも `run`/`runi`/`runall` に一本化しており、
  以前あった `py`/`pyrun`/`pyall` は廃止した）

### `command_not_found_handler`

- `run0` 〜 `run999` を `run <番号>` として実行（C++/Pythonどちらも対応）
- 上記以外は通常の `command not found` を表示

### `run0` function

- `command_not_found_handler` はコマンドが**見つからなかったとき**しか発火しない。
  systemd 256+ には sudo 類似の `run0`（`/usr/bin/run0` → `systemd-run`）が
  同梱されており、これが実在コマンドとして解決されてしまうとハンドラを通らず
  systemd 側の `run0` が実行される（WSL では polkit の対話認証ができず
  `Failed to start transient service unit: Access denied ...` で失敗する）
- そのため `run0` だけは明示的な関数 (`run0() { run 0 "$@" }`) で上書きしている。
  `run1` 〜 `run999` は同名バイナリが無いのでハンドラ任せで問題ない

### `mkprob` function

- `mkprob <lang> <problem>` 実行後、生成した `<problem>` ディレクトリへ自動で `cd`
- 実体コマンドは `command mkprob "$@"` で呼び出し

### `mkcontest` function

- `mkcontest <lang> <contest_prefix> ...` 実行後、**先頭の問題ディレクトリ**
  （個数指定なら `..._a`、サフィックス直接指定なら先頭のサフィックス）へ自動で `cd`
- 実体コマンド (`command mkcontest "$@"`) が `mktemp` で作った一時ファイルに
  cd 先の絶対パスを書き出し、それを読んで `cd` する
  （複数ディレクトリを作るため `mkprob` のように引数からそのまま cd 先を
  決められず、実体コマンド側から一時ファイル経由で伝えている）

### `next` / `back` function

- `next`/`back` 実行後、コンテスト内の次/前の問題フォルダへ自動で `cd`
- 実体コマンド (`command next` / `command back`) が解決した絶対パスを
  標準出力に返し、それを読んで `cd` する（失敗時は標準エラーにエラーを出して
  何もせず終了）

## Notes

- `.zshrc` の大半は Oh My Zsh のデフォルトコメント
- 実運用上重要なのは `competitive-env.zsh` を `source` している1行のみ
- リポジトリの `.zshrc` は `~/.zshrc` の参考用コピー（symlink ではない）。
  pnpm インストーラなど外部ツールが実際の `~/.zshrc` に直接追記することがあるため、
  両者は完全には一致しない場合がある。ただし競技プログラミング関連の設定は
  すべて `competitive-env.zsh` に集約されているため、`.zshrc` 側の差分を
  気にする必要はない
