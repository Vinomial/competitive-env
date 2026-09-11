# VSCode スニペット（C++ / Python）

競技プログラミングで使うVSCodeグローバルスニペットのマスターコピー。
実体はWindows側の `%APPDATA%\Code\User\snippets\` に置く必要があるため、
新しいPCでは以下のいずれかの方法で反映させる。

## 反映方法

### 方法A: シンボリックリンク（推奨、可能であれば）

Windows側で**通常のWindowsターミナル（WSL経由ではなく）**からPowerShellを開いて実行する。

```powershell
Remove-Item "$env:APPDATA\Code\User\snippets\cpp.json" -ErrorAction SilentlyContinue
Remove-Item "$env:APPDATA\Code\User\snippets\python.json" -ErrorAction SilentlyContinue
New-Item -ItemType SymbolicLink -Path "$env:APPDATA\Code\User\snippets\cpp.json" -Target "\\wsl.localhost\Ubuntu\home\binomial\Git\competitive-env\vscode-snippets\cpp.json"
New-Item -ItemType SymbolicLink -Path "$env:APPDATA\Code\User\snippets\python.json" -Target "\\wsl.localhost\Ubuntu\home\binomial\Git\competitive-env\vscode-snippets\python.json"
```

- `New-Item -ItemType SymbolicLink` はシンボリックリンク作成権限
  （`SeCreateSymbolicLinkPrivilege`）が必要。管理者としてPowerShellを実行するか、
  設定 > 更新とセキュリティ > 開発者向け で「開発者モード」を有効にしておく
- WSL側（`ln -s`など）から作成すると、WindowsネイティブのVSCodeからは
  リンク先（`/home/...`）を解決できず壊れたリンクになるので不可。
  必ずWindows側から、UNCパス（`\\wsl.localhost\...`）をターゲットにして作成すること
- 一度リンクを張れば、このリポジトリを更新するだけで全PCに反映される

### 方法B: 手動コピー（シンボリックリンクが使えない場合）

`.zshrc`と同様、手動での同期コピーで運用する。

```powershell
Copy-Item "\\wsl.localhost\Ubuntu\home\binomial\Git\competitive-env\vscode-snippets\cpp.json" "$env:APPDATA\Code\User\snippets\cpp.json" -Force
Copy-Item "\\wsl.localhost\Ubuntu\home\binomial\Git\competitive-env\vscode-snippets\python.json" "$env:APPDATA\Code\User\snippets\python.json" -Force
```

スニペットを追加・変更したら、このリポジトリ側を更新した後、他のPCでも
このコピーを再実行する必要がある（symlinkと違って自動追従しない）。

## `scope` フィールドについて

各スニペットには `"scope": "cpp"` / `"scope": "python"` を付けている。
このファイル自体（`cpp.json`/`python.json`という言語名ファイル名）は
ファイル名から言語スコープが暗黙に決まるため `scope` は本来不要で無視されるが、
`cp-solutions` リポジトリ側では `.vscode/cpp.code-snippets` /
`.vscode/python.code-snippets`（このファイルへのシンボリックリンク）として
読み込まれる。`.code-snippets` 形式はファイル名から言語を判定できないため、
明示的な `scope` が無いと全言語で候補に出てしまう。両方の読み込み方で
正しく動くように、マスター側にも `scope` を付けている。

## 関連するVSCode設定（`settings.json`）

`settings.json`自体はPCごとに固有の設定（MATLABパスなど）が混ざっているため
丸ごと共有はしない。以下の項目だけ、新しいPCの`settings.json`に手動で追記する。

```jsonc
"editor.snippetSuggestions": "top",       // スニペットを補完候補の最上部に表示
"C_Cpp.suggestSnippets": false,           // cpptools組み込みの do/for/while などのスニペット候補を無効化
"editor.suggestSelection": "recentlyUsedByPrefix", // 同じprefixで前回選んだ候補を自動選択
"editor.suggest.localityBonus": true      // カーソル付近のシンボルを優先表示
```

## スニペット一覧

内容の詳細は [cp-solutions リポジトリの docs](../../cp-solutions/docs/environment/vscode-snippets.md) を参照
（このリポジトリではファイルの実体のみを管理し、一覧表のドキュメントは
実際に使うプロジェクト側に置いている）。cp-solutions 側の
`.vscode/*.code-snippets` はこのディレクトリの `*.json` へのシンボリックリンク
なので、cp-solutions 側で個別に同期を取る必要はない。
