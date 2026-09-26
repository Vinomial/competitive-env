# competitive-env

競技プログラミング用のローカルコマンド集。  
C++/Python のビルド・実行・サンプル検証を短いコマンドで行う。

---

# 前提ディレクトリ構成

```text
~/competitive-env/
├── competitive-env.zsh   （PATH・シェル関数本体。~/.zshrc からはこれを source するだけ）
└── sh/
    ├── build.sh          （bd）
    ├── io.sh             （io / io term）
    ├── ioall             （C++ 全サンプル実行）
    ├── pyall.sh          （内部: run/runall から呼ばれる Python サンプル実行エンジン）
    ├── run               （自動判別で単体実行）
    ├── runi              （自動判別で対話実行）
    ├── runall            （自動判別で全サンプル実行）
    ├── mkprob.sh         （問題テンプレ生成: 1問）
    ├── mkcontest         （問題テンプレ生成: コンテスト単位で一括）
    ├── mkcontest.sh
    ├── stress            （ランダムテスト: gen/brute と main を自動比較）
    ├── stress.sh
    ├── resolve_target.sh （内部共有: run/runall/runi/stress の対象ファイル自動判定）
    ├── io_compare.sh     （内部共有: io/ioall/pyall.sh/stress の出力比較・checker対応・サンプル解決・TL 解決）
    ├── mkprob_core.sh    （内部共有: mkprob.sh/mkcontest.sh の1問生成ロジック）
    ├── mkfile            （カレントディレクトリに1ファイルだけ追加生成）
    ├── cpp_re_report.sh  （内部共有: io/ioall の RE 原因レポート）
    ├── fetchsample       （Windows Downloads の zip を問題フォルダへ取り込み）
    ├── fetchcontest      （コンテスト単位でzipを一括取り込み）
    ├── downloads_dir.sh  （内部共有: fetchsample/fetchcontest の Downloads フォルダ解決）
    ├── unzips            （サンプル zip を展開して samples/ へ整形）
    ├── next              （コンテスト内の次の問題フォルダへ移動）
    ├── back              （コンテスト内の前の問題フォルダへ移動）
    ├── resolve_sibling.sh（内部共有: next/back の兄弟フォルダ解決ロジック）
    ├── accept            （AC後に解答を git commit + push）
    ├── save              （リポジトリ全体を雑に git commit + push）
    └── git_push.sh       （内部共有: accept/save の push ロジック）
```

`resolve_target.sh` / `io_compare.sh` / `mkprob_core.sh` / `cpp_re_report.sh` / `resolve_sibling.sh` /
`git_push.sh` / `downloads_dir.sh` はコマンドとして直接実行するものではなく、
上記スクリプトから `source` される共通関数ライブラリ。

`~/.zshrc` に以下の1行を書くだけで PATH・関数一式が有効になる（詳細は [env.md](env.md) 参照）。

```zsh
source "$HOME/Github/personal/competitive-programming/competitive-env/competitive-env.zsh"
```

---

# 主要コマンド（C++ / Python）

## 自動ファイル判定のルール

引数なしのときは以下の順で自動判定する。

1) **現在のフォルダ名と同名の `*.cpp` / `*.py` があればそれを使う**  
2) なければ **`*.cpp` / `*.py` が1つだけある場合はそれを使う**  
3) それ以外はエラー（明示的にファイル名を指定）

---

## 出力の見た目

`run` / `runall` / `ioall` / `io` / `stress` は、結果を見やすくするため次の表示を行う。

- ステータスタグに色を付ける（端末出力時のみ。パイプ/リダイレクト先では自動的に無色になる。
  `NO_COLOR=1` を設定すると常に無色にできる）
  - 緑: `AC` / `OK` / `DEBUG-OK` / `TRACE-OK`
  - 赤: `WA` / `RE` / `MISMATCH` / `DEBUG-RE` / `TRACE-RE` / `GEN-ERROR` / `BRUTE-ERROR`
  - 黄: `TLE`
  - シアン: `RUN`
- サンプル1件だけ実行したとき（`run 0` / `run 5` など）は `--- input ---` / `--- output ---` の見出しを付けて表示する
- WAのときは `--- expected ---` / `--- actual ---` の見出しを付けて両方の出力を全文表示する
  （diff形式ではなく全文比較。一致する行は緑、一致しない行は赤で色分けする。
  `failures/*.diff` には従来通り `diff -u` 形式で保存される）
- `runall` の全サンプル実行後、`=== 全サンプルAC ===` などのまとめの右側に
  `[AC] 3  [WA] 1  (total 4)` のような内訳を表示する

---

## 実行時間制限（TLE 検出）

`run` / `runall` / `ioall` / `io` / `stress` は、実行時間が
制限を超えたら `[AC]`/`[RUN]` の代わりに `[TLE]` と表示し、失敗扱いにする。
**デフォルトは AtCoder の標準的な制限時間 2000ms** で、何も指定しなくても
常に判定される。

制限時間(ms)は次の優先順で解決される:

1) `--tl <ms>` オプション（明示指定、その場限り）
2) 問題フォルダ直下の `tl.txt`（1行に整数を書くだけ。制限時間が
   2000ms でない特殊な問題のときに使う）
3) どちらも無ければ既定値 2000ms

```bash
echo 3000 > tl.txt   # この問題だけ制限時間が 3000ms の場合
run --tl 3000        # その場限りで 3000ms 制限にする(tl.txt より優先)
```

既定値そのものを変えたい場合は環境変数 `DEFAULT_TL_MS` を設定する
（`.zshrc` などで `export DEFAULT_TL_MS=3000` のように）。

---

## run：単体実行（C++ / Python）

概要:
- C++: `build.sh` → `io term`
- Python: `python3` で直接実行
- C++ が RE した場合は sanitizer 付き debug build で同じ入力を再実行し、原因候補・該当行を表示

例:
```bash
run
run a
run a.cpp
run a.py
run --debug
run --tl 2000
```

---

## runi：対話実行（C++ / Python）

概要:
- C++: `build.sh` → `./a.out` を直接実行
- Python: `python3` で直接実行
- `in.txt` は使わず、標準入力をターミナルにつないだままにする
- `run --interactive` でも同じ実行になる

例:
```bash
runi
runi a
runi a.cpp
runi a.py
runi --debug
run --interactive a
```

インタラクティブ問題では、出力ごとに `cout << x << endl;` または `cout << x << '\n' << flush;` のように flush する。

---

## runall：全サンプル実行（C++ / Python）

概要:
- C++: `build.sh` → `ioall`
- Python: `pyall.sh`
- AtCoder と同様に、各行末の空白とファイル末尾の改行・空行の差を無視して比較する
- すべて通過したら **ソースを自動コピー**
- C++ が RE した場合は sanitizer 付き debug build で同じ入力を再実行し、原因候補・該当行を表示

例:
```bash
runall
runall a
runall a.cpp
runall a.py
runall --debug
runall --tl 2000
```

---

## run：サンプル番号指定実行

概要:
- `samples/` の `sample-<番号>.in/.out` を1件だけ検証
- 該当サンプルが無い場合は `in.txt` を使う（`out.txt` があれば比較）
- 自動判定は run/runall と同じ
- 実行時は **入力 → 空行 → 出力** の順に表示される

例:
```bash
run 0
run 5
run --sample 5
run --debug 0
```

---

## ioall：C++ 全サンプル一括実行

概要:
- `samples/` の `.in/.out` を全実行
- 各行末の空白とファイル末尾の改行・空行の差を無視して比較
- 実行時間を ms 表示
- NG の diff を `failures/` に保存
- `--clean` で `failures/` を削除
- 全サンプル OK のときは `failures/` を自動削除
- `run` / `runall` 経由の C++ RE は debug build で自動再実行される
- 直接使う場合も `ioall --debug-source a` のように source 名を渡すと同じ診断を出せる
- 実行時間制限は既定 2000ms。`--tl N` や `tl.txt` でこの問題だけ変更できる

例:
```bash
ioall
ioall --clean
ioall --debug-source a
ioall --tl 2000
```

---

## cleanfail：failures/ を削除

```bash
cleanfail
```

---

## fetchsample / fetchcontest / unzips：サンプル取得

概要:
- ブラウザ拡張（atcoder-sample-downloader）が Windows 側の Downloads に保存した zip を
  WSL 側の問題フォルダへ取り込み、`samples/` に展開する
- `fetchsample` は Downloads 内の**最新の zip を問題名に関わらず無条件に**取り込む
  （確認プロンプトは無いので、Sample DL 後は間を置かず `fetchsample` を叩く運用が前提）
  最後に `unzips` へ処理を委譲する
- `fetchcontest` は `mkcontest` で作ったコンテストルート（`abc999/abc999_a/`,
  `abc999_b/`, ... という構成）またはその中の問題フォルダ（`mkcontest` 直後の
  cd 先のまま実行できる）で実行する一括版。Downloads にある
  `<contest_prefix>_<suffix>.zip` を（`fetchsample` と違い**問題名で**）
  それぞれの問題フォルダへ振り分けてから `unzips` で一括展開する。
  コンテストの全問題ページを開いて Sample DL を済ませておけば、
  1コマンドでコンテスト分のサンプルをまとめて取得できる。
  該当する zip が無い問題は警告を出してスキップし、処理は継続する
- `unzips` は単体でも使え、手動で置いた zip や `abc999/` のようなコンテストルートでの一括展開にも対応する
- 展開後、`sample-0` を `in.txt` / `out.txt` に自動コピーする（`run` の既定入出力になる）
- 詳細な仕様（Downloads解決の優先順位、重複排除ロジック、エラーメッセージ一覧など）は [SAMPLE_FETCH.md](SAMPLE_FETCH.md) を参照

例:
```bash
fetchsample                 # カレントディレクトリ名を問題名として取り込み〜展開まで一括実行
fetchsample abc999_a        # 問題名を明示指定

fetchcontest                # abc999/ または abc999_a/ で実行: abc999_a.zip 〜 abc999_g.zip をまとめて取り込み〜展開

unzips                      # カレントの *.zip を展開
unzips --keep                # 展開後もzipを残す
```

---

# mkprob：問題テンプレ生成

## 概要

問題用のディレクトリを自動生成する。  
C++ または Python を選択できる。

---

## 仕様

- フォルダ名：`abc365_a` → `abc365_a`
- ファイル名：`<問題名>.<cpp|py>`
- C++ の場合は初期コードが自動で書き込まれる
- C++ の場合は `in.txt` / `out.txt` を生成する
- Python の場合は空ファイルを生成する
- 生成後、自動で `cd` した上で、生成したソースファイルを `code`（VSCode remote-cli）で開く
  （`code` コマンドが無い環境では開く処理は自動的にスキップされる）

---

## 使い方

```bash
mkprob cpp abc365_a
```

生成される構成：
```text
abc365_a/
├── abc365_a.cpp
├── in.txt
├── out.txt
```

```bash
mkprob py abc365_b
```

生成される構成：
```text
abc365_b/
└── abc365_b.py
```

---

# mkcontest：コンテスト単位で問題を一括生成

## 概要

`mkprob` はそのまま（過去問を1問だけ解くときに使う）、  
コンテスト本番で複数問まとめて用意したいときは `mkcontest` を使う。  
内部的には `mkprob` と同じ生成ロジック（`sh/mkprob_core.sh`）を問題数ぶん繰り返し呼ぶだけ。

---

## 仕様

- `<contest_prefix>` という親フォルダを作り（無ければ新規作成、あれば再利用）、
  その中に `<contest_prefix>_<suffix>` という子フォルダを作る
  （子フォルダの命名規則は `mkprob` と同じ）
- 個数指定 or サフィックス直接指定のどちらかを選べる
  - 個数指定（1〜26の整数1つ）: `a` から順に `<count>` 問ぶん生成
  - サフィックス直接指定（2つ以上、または数字以外を含む）: 指定した順にそのまま生成
- 既に存在する子フォルダはスキップし、他のフォルダの生成は継続する
  - 1件でもスキップがあれば最後に一覧を表示し、終了コード 1 を返す
- 実行後、**先頭の問題（通常は `a`）のディレクトリへ自動で `cd` する**
  （`mkprob` と同様、`.zshrc` の `mkcontest` 関数経由。コンテストは大抵
  `a` から解き始めるため）
  - 個数指定なら常に `a` へ、サフィックス直接指定なら先頭に書いたサフィックスへ
  - 既にスキップされた（＝既存の）ディレクトリでも存在していれば `cd` する
- 親フォルダが既にある状態で再実行すれば、後から問題を追加生成できる
  （例: コンテスト後に `ex` 問題だけ追加）

---

## 使い方

```bash
mkcontest cpp abc468 7        # abc468/ に abc468_a 〜 abc468_g を作成し cd
mkcontest cpp abc468 a b c ex # abc468/ に abc468_a / abc468_b / abc468_c / abc468_ex を作成
mkcontest py arc199 6         # arc199/ に arc199_a 〜 arc199_f を作成し cd
```

生成される構成（`mkcontest cpp abc468 7` の場合）：
```text
abc468/
├── abc468_a/
│   ├── abc468_a.cpp
│   ├── in.txt
│   └── out.txt
├── abc468_b/
│   ├── abc468_b.cpp
│   ├── in.txt
│   └── out.txt
...(abc468_g まで同様)
```

---

# mkfile：カレントディレクトリに1ファイルだけ追加生成

## 概要

`mkprob`/`mkcontest` は必ず新しいディレクトリを作るが、同じ問題フォルダの中に
別解・別バージョンをもう1本追加したいときは `mkfile` を使う。

- 新しいディレクトリは作らない（カレントディレクトリに直接ファイルを作る）
- `in.txt`/`out.txt` は生成・上書きしない（既存のものを使う想定。
  複数ファイルがある状態で `run`/`runall` するときは
  `run <name>`/`runall <name>` のようにファイル名を明示する）
- C++ の場合はテンプレートをコピーする。Python の場合は空ファイルを作る
- 生成先のファイルが既に存在する場合はエラーで終了する

## 使い方

```bash
cd abc456/abc456_b
mkfile cpp abc456_b2   # abc456_b2.cpp を追加生成
mkfile py abc456_b3    # abc456_b3.py を追加生成

run abc456_b2          # 複数ファイルがあるので明示指定
```

---

# next / back：隣の問題フォルダへ移動

## 概要

`mkcontest` で作った `<contest_prefix>/<contest_prefix>_<suffix>/` という構成の中で、
今いる問題フォルダから見て次/前の問題フォルダへ `cd` する。

- 提出してACをもらった後、次の問題へ手で `cd ../abc999_b` する手間を省くためのもの
- ローカルのサンプルがAC しているかどうかは見ない（提出してのACとは別物なので、
  ツール側では判定しない。あくまで移動するだけ）
- 兄弟フォルダは「親ディレクトリ名 + `_`」から始まるフォルダ名をフォルダ名順（`sort`）に
  並べたものとして解決する（`abc999/` 配下の `abc999_a`, `abc999_b`, `abc999_ex` など）
- 最初/最後の問題でさらに `next`/`back` すると `error: already at the last/first problem ...` で失敗する
- 兄弟フォルダが見つからない場合や、今のフォルダが `<contest_prefix>_*` の命名に沿っていない場合も
  エラーになる（`mkprob` で単発に作った、コンテストに属さない問題フォルダなど）
- 移動先で `<フォルダ名>.cpp`/`.py`（無ければ唯一の `*.cpp`/`*.py`）を `code` で自動的に開く
  （`mkprob` と同じ挙動。複数ソースがあって判定できない場合は開かない）

## 使い方

```bash
cd abc999/abc999_a
next          # abc999/abc999_b へ移動
next          # abc999/abc999_c へ移動
back          # abc999/abc999_b へ戻る
```

---

# accept：AC後に解答を git commit

## 概要

AtCoder に提出してACをもらった後、今いる問題フォルダの解答を手動で git commit し、
続けて git push まで行う。

- 対象ファイルの自動判定は `run`/`runall` と同じ
- `git add` するのは解答ファイル（`.cpp`/`.py`）と `in.txt` / `out.txt` / `tl.txt` / `samples/`
  （存在するものだけ。`a.out` などのビルド成果物は含めない）
- コミットメッセージは `# <フォルダ名を大文字化・アンダースコア除去したもの>` を先頭に、
  解答ファイルが新規なら「解法を追加」、既存ファイルの変更なら「解法を更新」、
  サンプル関連ファイルにも変更があれば「サンプルを追加/更新」を付け足して自動生成する
  （例: `# ABC468D - 解法を追加 - サンプルを追加`）
- 何もステージする変更が無い場合（変更なし、または既にコミット済み）はエラーで終了する
- git リポジトリの外で実行するとエラーになる
- push は `git push`（現在のブランチに upstream が無ければ
  `git push --set-upstream origin <branch>` で初回設定込みで実行）。
  `--force` は使わない
- push が失敗した場合（upstream 設定済みで conflict がある場合など）は
  警告を出して終了する。**commit 自体は成功しているので、そのままローカルには残る**
- `--no-push` を付けると commit だけ行い push はしない

## 使い方

```bash
cd abc468/abc468_d
accept              # commit + push
accept --no-push    # commit のみ
```

---

# save：リポジトリ全体を雑に commit + push

## 概要

`accept` が1問単位・構造化コミットメッセージなのに対し、`save` は
「今リポジトリ内にある変更を全部まとめて commit + push したい」ときに使う。
実行しているディレクトリに関係なく、リポジトリ全体が対象になる。

- `git add -A` でリポジトリ全体の変更（新規・更新・削除）をステージする
- コミットメッセージは省略時 `wip: <日時>`（引数で明示指定も可）
- ステージする変更が無ければエラーで終了する
- push の挙動は `accept` と同じ（upstream 未設定なら初回設定込みで push、
  `--force` は使わない、push 失敗時は警告のみでcommit自体は残る）
- `--no-push` を付けると commit だけ行い push はしない

## 使い方

```bash
save                          # git add -A → commit(wip: 日時) → push
save "整理中"                  # メッセージを指定
save --no-push                # commit のみ
```

---

# stress：ランダムテスト（stress test）

## 概要

ランダムな入力を生成し、遅くても確実に正しい参照実装（brute force）と
本命の実装（main）の出力を自動で比較し続ける。一致しなくなった/main が
異常終了した/制限時間を超えた時点で止まり、再現用の入力を保存する。
WA の原因調査や、サンプルには出てこないコーナーケースの発見に使う。

---

## 仕様

カレントディレクトリに以下が必要:

- `gen.cpp` / `gen.py`：`argv[1]` にシード(整数)を受け取り、標準出力に
  ランダムな入力を1件出力するジェネレータ
- `brute.cpp` / `brute.py`：遅くても良いので確実に正しい参照実装
- 本命の実装（`main_source` を省略した場合は `run`/`runall` と同じ自動判定）

C++/Python は各ファイルごとに自由に混在できる（例: main は C++、
gen/brute は Python、など）。

動作:

- `seed` を `--seed-start` から1つずつ増やしながら `--count` 回繰り返す
- 各回: `gen <seed>` → 入力 → `main` と `brute` それぞれに投入 → 出力比較
  （行末空白・末尾改行の差は無視。`ioall`/`pyall.sh` と同じ比較ロジック）
- 不一致 / `main` の異常終了(RE) / 制限時間超過(TLE、既定 2000ms。
  `--tl` か `tl.txt` で変更可)のいずれかが起きた時点で停止し、
  `stress_fail/` に `in.txt` / `main_out.txt` / `brute_out.txt` を保存する
- `brute` 自体が異常終了した場合は `brute` 側の不具合として個別に報告する
- `--debug` を付けると `main` だけ sanitizer 付き debug build でテストする
  （`gen`/`brute` は常に release build）
- 最後まで不一致が無ければ成功
- `checker.cpp`/`checker.py` があれば、brute/main の厳密一致の代わりに
  それを使って判定する（詳細は次章「checker：スペシャルジャッジ対応」参照）

---

## 使い方

```bash
stress                      # main_source は自動判定、100回
stress a                    # main_source を明示指定
stress --count 300          # 300回試す
stress --seed-start 1000    # シードを 1000 から始める
stress --debug              # main を sanitizer 付きでテスト
stress --tl 2000            # main の実行時間制限を 2000ms にする
```

生成される構成（`sumprob/` に `sumprob.cpp` / `gen.cpp` / `brute.cpp` がある場合）：
```text
sumprob/
├── sumprob.cpp
├── gen.cpp
├── brute.cpp
└── stress_fail/       # 不一致が見つかった場合のみ生成
    ├── in.txt
    ├── main_out.txt
    ├── main_err.txt    # main が RE した場合のみ
    └── brute_out.txt
```

---

# checker：スペシャルジャッジ対応

## 概要

`run`/`runall`/`ioall`/`pyall`/`stress` は既定では「サンプル出力と完全一致するか」
（空白正規化した文字列比較）でしか正誤判定できない。複数の正解がありうる構築問題や、
誤差を許容する実数問題ではこれだけでは正しく判定できないため、問題フォルダに
`checker.cpp`/`checker.py` を置くと、以降はそれを使った判定に自動的に切り替わる。

## 仕様

- 対象コマンド: `run` / `runall` / `ioall` / `pyall`（サンプルとの比較）、
  `stress`（brute/mainの比較）
- 置き場所: 問題フォルダ直下に `checker.cpp` または `checker.py`
  （`gen.cpp`/`brute.cpp` と同じ命名規則）
- 呼び出し形式: `checker <input_file> <expected_output_file> <actual_output_file>`
  - `run`/`runall`/`ioall`/`pyall`: expected = サンプルの `.out`、actual = 実行結果
  - `stress`: expected = brute の出力、actual = main の出力
    （厳密一致ではなく「input に対して actual が妥当か」を判定する用途で使う）
- 判定: exit 0 なら正解(AC)、非0なら不正解(WA/MISMATCH)
- `checker.cpp` は初回実行時に `checker.out` としてビルドされる
  （`ioall`/`pyall` では `a.out` と同様その場に残る。`stress` では実行後に削除される）
- `checker.cpp` のビルドに失敗した場合はエラーで終了する
- `checker.cpp`/`checker.py` が無い場合は今まで通り exact diff で判定する
  （既存の挙動に影響しない）

## 使い方

```cpp
// checker.cpp の例: 誤差 1e-6 を許容する
#include <bits/stdc++.h>
int main(int argc, char **argv)
{
    std::ifstream exp(argv[2]), act(argv[3]);
    double e, a;
    exp >> e;
    act >> a;
    return (std::fabs(e - a) < 1e-6) ? 0 : 1;
}
```

```bash
runall   # checker.cpp があれば自動的にそれで判定される
stress   # checker.cpp があれば main/brute の比較にも使われる
```

---

# bd：C++ コンパイル

## 概要

指定した C++ ファイルをコンパイルし `a.out` を生成する。  
`atcoder` が含まれる場合は `./ac-library` を include する。  
`gmpxx.h` が含まれる場合は `-lgmpxx -lgmp` を付与する。  
`debug` 指定時は sanitizer、`_GLIBCXX_DEBUG`、デバッグ情報を有効化する。  
`trace` 指定時は sanitizer とデバッグ情報を有効化し、ユーザーコードの行番号特定を優先する。  
debug build の出力先は通常 `a.out`、`CPP_OUT=./a.debug.out bd a debug` のように環境変数で変更できる。

---

## 使い方

```bash
bd a
bd
bd a debug
bd a trace
```

---

# io：単一入力の実行

## 概要

`in.txt` を標準入力として `a.out` を実行する。  
デフォルトは `out.txt` に出力し、`term` 指定時は標準出力に表示する。  
`term` のときは **入力 → 空行 → 出力** の順に表示される。

---

## 使い方

```bash
io
io term
```

---

# トラブルシューティング

- **`main.cpp` / `main.py` が見つからない**
  - 引数なし実行時の自動判定が失敗している。  
    フォルダ名と同名のファイルが無い or 複数ファイルがある場合は  
    `run a` / `runall a` のように明示指定する。
- **コピーされない**
  - `xclip` が必要。無い場合は警告を出してコピーをスキップする。
- **`Segmentation fault` / `[RE]` の原因が分からない**
  - `run 0` / `runall` 経由なら RE 時に debug build で自動再実行する。  
    `配列・vector などの範囲外アクセス`, `0除算`, `符号付き整数オーバーフロー`, `nullptr 参照` などは原因候補として表示される。
  - 行番号が debug build だけで取れない場合は trace build でもう一度走らせ、`location:` と該当コード行を表示する。
  - 次回実行で RE が消えた場合は `failures/*.err`, `a.debug.out`, `a.trace.out` を自動削除する。
  - 最初から範囲チェック付きで走らせたい場合は `run --debug 0` / `runall --debug` を使う。
