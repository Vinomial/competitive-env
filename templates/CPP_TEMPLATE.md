# C++ テンプレート仕様（`templates/cpp_template.cpp`）

`sh/mkprob.sh` で `cpp` を指定したときにコピーされるテンプレートの、**現在の実装内容**をまとめたドキュメントです。

---

## 1. 基本構成

### ヘッダ・名前空間

```cpp
#include <bits/stdc++.h>
using namespace std;
```

### 型エイリアス

```cpp
using ll = long long;
using ld = long double;
using i128 = __int128_t;
using u32 = uint32_t;
using u64 = uint64_t;
using u128 = __uint128_t;
```

### ループ/汎用マクロ

```cpp
#define rep0(i, n) for (int i = 0; i < (int)(n); ++i)
#define rep(i, a, b) for (int i = (int)(a); i < (int)(b); ++i)
#define rrep(i, a, b) for (int i = (int)(a); i > (int)(b); --i)
#define srep(i, a, b, step) \
    for (long long i = (a); (step) > 0 ? i < (b) : i > (b); i += (step))

#define all(v) (v).begin(), (v).end()

template <class C> auto MIN(const C &c); // 最小要素の値
template <class C> auto MAX(const C &c); // 最大要素の値
```

- `MIN` / `MAX` はマクロではなく関数（テンプレート）。任意のコンテナを受けて
  最小/最大要素の値を返す。関数なので引数の式は1回しか評価されない
- 通常は `min_element`/`max_element` の O(n) だが、**デフォルト比較の
  `set`/`multiset` に対しては先頭/末尾を直接見る O(1)** に自動で切り替わる。
  `set<int, greater<int>>` のようにカスタム比較の場合は、数値的な最小/最大を
  保つため O(n) 側にフォールバックする（結果は常に `min_element` と同じ）

### 定数

```cpp
constexpr int INF = (1 << 29);
constexpr ll INFLL = (1LL << 60);
constexpr ll MOD = 998244353;
constexpr ll MOD2 = 1000000007;
```

- `INF`/`INFLL` は、2つ足してもオーバーフローしないように意図的に最大値の半分以下に
  抑えている（`1 << 30` / `1LL << 62` だと `INF + INF` がそれぞれ `int`/`ll` の
  範囲をちょうど1超えてオーバーフローするため。min-plus DP・ダブリングなどで
  到達不能同士を足す場面で起きうる）

---

## 2. 入出力ユーティリティ（`fastio`）

### 入力: `read(...)`

`cin` ベースの入力関数です。可変引数でまとめて読めます。

対応型:
- 基本型（`int`, `ll`, `ld`, `i128`, `u128`, `double`, `string` など）
- `pair`
- `tuple`
- `array`
- `vector`
- `deque`

例:

```cpp
int n;
ll x;
ld y;
i128 z;
string s;
read(n, x, y, z, s);

vector<int> a(n);
read(a);
```

`i128` / `u128` は10進整数文字列として読み込みます。

### 出力: `print(...)`

`print(a, b, c)` は空白区切りで出力し、最後に改行します。

内部 `wt(...)` が対応している型:
- 基本型（`i128` / `u128` を含む）
- `val()` を持つ型（`Modint9` など）は `val()` を出力
- `string`, `const char*`
- `pair`, `tuple`
- `array`, `vector`, `vector<vector<T>>`, `deque`
- `priority_queue`
- `set`, `multiset`, `unordered_set`
- `map`, `unordered_map`

`priority_queue` はコピーを作って `top()/pop()` で出力するため、元のキューは変更されません（優先度順に表示）。

小数は常に小数点以下15桁で固定表示:
- `float`, `double`, `long double`: `fixed << setprecision(15)`
- 15桁の根拠: 判定誤差は「答えの傾き × 丸め誤差 0.5·10^(-p)」で効くため、
  傾きが 1e5 級の問題でも誤差 ~1e-10 に収まり、許容 1e-6 / 1e-9 のどちらでも
  ボトルネックにならない（10桁時代に傾き ~3e4 の問題で WA した実例あり）。
  `long double` の有効桁（x86 80bit で ~18桁）の範囲内なので無意味な桁も出さない

`i128` / `u128` は10進整数文字列として出力します。`vector<i128>` や `pair<i128, u128>` など、コンテナ内の128bit整数も同じルールで出力できます。

### Yes/No 出力: `yesno(cond)`

```cpp
void yesno(bool cond); // cond ? "Yes" : "No" を出力して改行
```

```cpp
yesno(a + b == c); // "Yes" or "No"
```

---

## 3. 宣言+入力マクロ

宣言してすぐ `read` するためのショートカットです。

```cpp
#define INT(...)  int __VA_ARGS__; read(__VA_ARGS__)
#define LL(...)   ll __VA_ARGS__; read(__VA_ARGS__)
#define U32(...)  u32 __VA_ARGS__; read(__VA_ARGS__)
#define U64(...)  u64 __VA_ARGS__; read(__VA_ARGS__)
#define STR(...)  string __VA_ARGS__; read(__VA_ARGS__)
#define CHAR(...) char __VA_ARGS__; read(__VA_ARGS__)
#define DBL(...)  double __VA_ARGS__; read(__VA_ARGS__)
#define LD(...)   ld __VA_ARGS__; read(__VA_ARGS__)
#define I128(...) i128 __VA_ARGS__; read(__VA_ARGS__)
#define U128(...) u128 __VA_ARGS__; read(__VA_ARGS__)

#define VEC(type, name, size) \
    vector<type> name(size); \
    read(name)

#define DEQ(type, name, size) \
    deque<type> name(size); \
    read(name)

#define VEC2(type, name1, name2, size) \
    vector<type> name1, name2;         \
    read_cols(size, name1, name2)

#define VEC3(type, name1, name2, name3, size) \
    vector<type> name1, name2, name3;         \
    read_cols(size, name1, name2, name3)

#define SET(type, name, size) \
    set<type> name = read_set<type>(size)

#define MSET(type, name, size) \
    multiset<type> name = read_multiset<type>(size)

#define VV(type, name, h, w) \
    vector<vector<type>> name(h, vector<type>(w)); \
    read(name)

#define VEC0(type, name, size) vector<type> name(size)
#define VV0(type, name, h, w) vector<vector<type>> name(h, vector<type>(w))
#define VECI(type, name, size, init) vector<type> name(size, init)
#define VVI(type, name, h, w, init) vector<vector<type>> name(h, vector<type>(w, init))
#define VVV0(type, name, d1, d2, d3) vector<vector<vector<type>>> name(d1, vector<vector<type>>(d2, vector<type>(d3)))
#define VVVI(type, name, d1, d2, d3, init) vector<vector<vector<type>>> name(d1, vector<vector<type>>(d2, vector<type>(d3, init)))
```

- `VVV0`/`VVVI`: 3次元vector版（3次元累積和・3次元DPなどで使用）。
  `read(...)` による入力読み込みは無い（`VV` に対する `VVV` のような読み込み版は用意していない）
- `VEC2`/`VEC3`: `a1 b1 / a2 b2 / ...` のような**行ごとに複数の値が並ぶ入力を列ごとの
  vector に振り分けて**読む。内部の `read_cols(n, A, B, ...)` を直接呼べば、
  `read_cols(n, A, S)`（`vector<ll>` と `vector<string>`）のように**列ごとに型が違う**場合にも使える

使用例:

```cpp
INT(n, m);
LD(rate);
I128(big);
VEC(int, a, n);
DEQ(int, dq, n);              // dequeで受け取る（両端からの追加・削除がある問題）
VEC2(ll, A, B, n);            // a1 b1 / a2 b2 / ... を A と B に振り分けて読む
vector<ll> C; vector<string> S;
read_cols(n, C, S);           // 列ごとに型が違う場合は read_cols を直接使う
SET(int, s, n);               // 重複は自動で1つにまとまる
MSET(int, ms, n);             // 重複も保持する
VV0(ll, dist, n, n);
VECI(ll, dp, n, -1);          // 任意の初期値
VVI(ll, cost, n, n, (1LL << 60)); // 任意の初期値
VVV0(ll, S, n, h + 1, w + 1);      // 3次元累積和など
```

---

## 4. `set` / `multiset` 補助（近傍取得・削除）

`std::set` の Python 風集合演算子はテンプレートから外し、ライブラリ `library/cpp/data_structure/set_operations.hpp` に分離しています。

### 近傍取得（iterator）

```cpp
ge_it(c, x)
```
- `x` 以上の最小要素を指す iterator（`lower_bound`）
- 存在しなければ `c.end()`

```cpp
le_it(c, x)
```
- `x` 以下の最大要素を指す iterator
- 存在しなければ `c.end()`

例:

```cpp
auto it1 = ge_it(st, x);
if (it1 != st.end()) {
    ll v = *it1;
}

auto it2 = le_it(st, x);
if (it2 != st.end()) {
    ll v = *it2;
}
```

### 近傍取得（値）

```cpp
ge_val(c, x)
le_val(c, x)
```

- 戻り値は `typename C::value_type`（値を直接返す）
- 要素が存在しない場合は `std::out_of_range` を送出

例:

```cpp
ll a = ge_val(st, x); // x以上の最小要素
ll b = le_val(st, x); // x以下の最大要素
```

存在しない可能性がある場合:

```cpp
try {
    ll a = ge_val(st, x);
    print(a);
} catch (const out_of_range &) {
    // 見つからないときの処理
}
```

### 削除

```cpp
discard_one(c, x)
```
- `set`: `x` を削除（0 or 1 個）
- `multiset`: `x` を **1個だけ** 削除
- 戻り値: `bool`（削除成功なら `true`）

```cpp
discard_all(c, x)
```
- `set`: `x` を削除（0 or 1 個）
- `multiset`: `x` を **全部** 削除
- 戻り値: `int`（削除した個数）

例:

```cpp
bool ok = discard_one(ms, x); // multiset で1個だけ
int cnt = discard_all(ms, x); // multiset で全部
```

---

## 5. 補助関数

### `chmin` / `chmax`

```cpp
template <class T, class U> bool chmin(T &x, const U &y);
template <class T, class U> bool chmax(T &x, const U &y);
```

- `chmin(x, y)`: `y < x` なら `x = y` に更新して `true` を返す。更新しなければ `false`
- `chmax(x, y)`: `x < y` なら `x = y` に更新して `true` を返す。更新しなければ `false`
- 最適化DPの遷移や「候補を全部試して最良値を残す」処理の短縮形。
  代入先を1回しか書かないので、`dp[i][j]` のような長い式でも添字の書き間違いが起きにくい
- 戻り値で「更新できたか」が分かるので、Dijkstra の「距離を縮められたときだけ
  キューに積む」のような条件付き処理が1行で書ける
- `T` と `U` は別型でもよい（`chmin(ll変数, int値)` など）。更新時は `T` にキャストして代入する

```cpp
// DP遷移
chmin(dp[i + 1], dp[i] + cost);

// 候補の最大値を集める
ll best = -INFLL;
for (auto v : candidates) chmax(best, v);

// Dijkstra: 更新できたときだけ push
if (chmin(dist[to], dist[v] + w)) pq.push({dist[to], to});
```

### 二分探索（`vector`）

```cpp
template <class T, class U>
int bisect_left(const vector<T> &v, const U &x);

template <class T, class U>
int bisect_right(const vector<T> &v, const U &x);
```

- `bisect_left`: `x` 以上の最初の位置
- `bisect_right`: `x` より大きい最初の位置
- キーは要素と別の型でもよい（`vector<ll>` に `int` のキーを渡す等。`chmin`/`chmax` と同じ方針）

### 切り上げ・切り下げ除算

```cpp
template <class T, class U> auto floor_div(T a, U b);
template <class T, class U> auto ceil_div(T a, U b);
```

- `floor_div(a, b)`: `floor(a / b)`、`ceil_div(a, b)`: `ceil(a / b)` を整数演算で返す
- **負数でも数学的に正しい**（C++ の `/` はゼロ方向切り捨てなので `-7 / 2 == -3` だが、
  `floor_div(-7, 2) == -4`。手書きの `(a + b - 1) / b` も負数で壊れるパターン）
- 型が混在してもよい（`int` と `ll` など。通常の算術変換に従う）

### 整数平方根 / 平方数判定

```cpp
template <class T> T isqrt(T n);
template <class T> bool is_square(T n);
```

- `isqrt(n)`: `floor(sqrt(n))` を `n` と同じ型で返す（`ll` / `i128` どちらでも呼べる。`0 <= n`）
- `is_square(n)`: `n` が平方数なら `true`
- 初期値には `sqrtl` を使い、浮動小数点誤差によるずれを `while` で補正する
- `r * r` が `T` を超え得るため、比較は常に `i128` に拡張して行う
- テンプレートなので `ll n` に対しては `isqrt(n)` が今まで通り `ll` で返り、
  `i128 n` に対しても同じ呼び方で正しく `i128` の範囲で計算される
  （`isqrt128` のような別関数を用意する必要はない）

例:

```cpp
ll n;
cin >> n;

ll side = isqrt(n);
if (is_square(n)) {
    // n is a square number
}
```

### べき乗

```cpp
template <class T> T ipow(T a, long long e);
```

- 単純な繰り返し二乗法
- `a` の型 `T` は呼び出し時の引数から推論される（`ll a` なら `ll` で、
  `i128 a` なら `i128` で計算される。`ipow128` のような別関数は不要）
- オーバーフローは呼び出し側で注意（`T` の範囲内で計算されるだけで、
  `i128` を渡しても無制限になるわけではない）

### `argsort` / 並び順の適用

```cpp
template <class T, class Alloc, class Compare = less<T>>
vector<int> argsort(const vector<T, Alloc> &v, Compare comp = Compare());

template <class... Vecs>
void apply_order(const vector<int> &order, Vecs &...vs);

template <class Key, class Alloc, class... Vecs>
void sort_by_key(vector<Key, Alloc> &key, Vecs &...vs);
```

用途:
- `argsort(v)`: `v` を昇順に見たときの index 列を返す
- `argsort(v, comp)`: 比較関数 `comp` の順に見たときの index 列を返す
- `apply_order(order, a, b, ...)`: `order[i]` 番目の要素を新しい `i` 番目にする
- `sort_by_key(key, a, b, ...)`: `key` を基準にして、対応する複数の `vector` をまとめて並べ替える

`argsort` は `stable_sort` を使うため、同じ key の相対順序は保たれます。  
`apply_order` はすべての `vector` の長さが `order.size()` と一致していることを `assert` で確認します。

例: 1本の `vector` から並び順だけ作る

```cpp
vector<ll> a = {30, 10, 20};
vector<int> order = argsort(a); // {1, 2, 0}
```

例: 1つの key で複数の `vector` を並べ替える

```cpp
vector<ll> x = {3, 1, 2};
vector<string> name = {"c", "a", "b"};
vector<ll> cost = {300, 100, 200};

sort_by_key(x, name, cost);

// x    = {1, 2, 3}
// name = {"a", "b", "c"}
// cost = {100, 200, 300}
```

例: 降順や独自の順序で並べ替える

```cpp
vector<ll> score = {80, 100, 90};
vector<int> id = {0, 1, 2};

auto order = argsort(score, greater<ll>());
apply_order(order, score, id);

// score = {100, 90, 80}
// id    = {1, 2, 0}
```

### 反転コピー

```cpp
template <class C>
C reversed(C c);
```

- 引数のコピーを反転して返す（元データは変更しない）

### 総和

```cpp
template <class T>
T sum(const vector<T> &v);
```

- `accumulate(..., T(0))` で `v` の要素と同じ型 `T` の合計を返す
  （`vector<ll>` なら `ll`、`vector<i128>` なら `i128` で計算される。
  以前は内部で `0LL` 固定だったため `vector<i128>` を渡すと各要素が
  `ll` に切り詰められて壊れていた）

### シーケンス結合（`vector` / `array`）

```cpp
template <class T, class AllocA, class AllocB>
vector<T, AllocA> concat(const vector<T, AllocA> &a, const vector<T, AllocB> &b);

template <class T, class AllocA, class AllocB>
vector<T, AllocA> operator+(const vector<T, AllocA> &a, const vector<T, AllocB> &b);

template <class T, class AllocA, class AllocB>
vector<T, AllocA> &operator+=(vector<T, AllocA> &a, const vector<T, AllocB> &b);

template <class T, size_t N, size_t M>
array<T, N + M> concat(const array<T, N> &a, const array<T, M> &b);
```

- `vector` は `A + B` で新しい連結ベクタを返す
- `vector` は `A += B` で `A` の末尾に `B` を追記する
- `concat(A, B)` でも `vector` 連結が可能
- `array` はサイズ固定なので `concat(A, B)` で `array<T, N+M>` を新規作成して返す

例:

```cpp
vector<ll> A = {1, 2, 3};
vector<ll> B = {4, 5};
vector<ll> C = A + B; // {1,2,3,4,5}
A += B;               // A も {1,2,3,4,5}

array<int, 2> X = {1, 2};
array<int, 3> Y = {3, 4, 5};
auto Z = concat(X, Y); // array<int, 5> {1,2,3,4,5}
```

### `join` 系

```cpp
template <class It>
string join(It first, It last, const string &sep);

string join(const vector<string> &v, const string &sep);
string join(const string &s, const string &sep);

template <class C>
string join(const C &c, const string &sep);
```

用途:
- コンテナを区切り文字付き文字列にまとめる
- 文字列 `s` の各文字の間に `sep` を挟む

### 文字列 `count`

```cpp
int count(const string &s, char c);
int count(const string &s, const string &t);
```

- `count(s, c)`: 文字 `c` の出現回数
- `count(s, t)`: 部分文字列 `t` の出現回数（重なりなし）
- `t` が空文字なら `s.size() + 1` を返す（Python `str.count` 相当）

例:

```cpp
string s = "ababa";
int a = count(s, 'a');     // 3
int b = count(s, "aba");   // 1
```

### 文字列 `replace`

```cpp
string replace(string s, const string &from, const string &to);
string replace(string s, char from, char to);
```

- `replace(s, from, to)`: `s` 内の `from` をすべて `to` に置換した新しい文字列を返す
- `replace(s, c1, c2)`: 文字 `c1` をすべて `c2` に置換した新しい文字列を返す
- 元の `s` は変更しない（コピーを返す）

例:

```cpp
string s = "ababa";
string t = replace(s, "aba", "x"); // "xba"
string u = replace(s, 'a', 'z');   // "zbzbz"
```

### ランレングス圧縮: `rle`

```cpp
template <class C> auto rle(const C &s);
```

- 連続する同じ値をまとめて `vector<pair<要素型, int>>`（値, 連続回数）で返す
- `string` でも `vector<T>` でも使える

```cpp
auto r = rle(string("aabbba")); // {('a',2), ('b',3), ('a',1)}
for (auto [c, len] : r) { ... }
```

### グリッド探索の方向配列・範囲内判定

```cpp
constexpr int DX4[] = {1, 0, -1, 0};
constexpr int DY4[] = {0, 1, 0, -1};
constexpr int DX8[] = {1, 1, 0, -1, -1, -1, 0, 1};
constexpr int DY8[] = {0, 1, 1, 1, 0, -1, -1, -1};

bool in_grid(ll i, ll j, ll h, ll w);
```

- `DX4`/`DY4`: 上下左右の4方向。`dx` が行方向（i）、`dy` が列方向（j）の差分
- `DX8`/`DY8`: 斜めを含む8近傍
- `in_grid(i, j, h, w)`: `0 <= i < h && 0 <= j < w` の短縮形。
  `int` でも `ll` でも渡せる

```cpp
INT(h, w);
VEC(string, S, h);  // 1行1文字列でグリッドを読む

// グリッドBFSの近傍列挙
rep0(d, 4)
{
    int ni = i + DX4[d], nj = j + DY4[d];
    if (!in_grid(ni, nj, h, w) || S[ni][nj] == '#')
        continue;
    // ...
}
```

### グリッド回転・反転・転置

```cpp
template <class G> G rotate90(const G &g);
template <class G> G rotate90_cw(const G &g);
template <class G> G rotate180(const G &g);
template <class G> G transpose(const G &g);
template <class G> G flip_h(const G &g);
template <class G> G flip_v(const G &g);
```

- `rotate90(g)`: `g`（h行w列）を**反時計回り**に90度回転した w行h列のグリッドを返す
  （`result[w-1-j][i] = g[i][j]`）。4回適用すると元に戻る
- `rotate90_cw(g)`: **時計回り**に90度回転した w行h列のグリッドを返す
  （`result[j][h-1-i] = g[i][j]`）。`rotate90` の逆変換
  （`rotate90(rotate90_cw(g)) == g`）
- `rotate180(g)`: 180度回転した h行w列のグリッドを返す
  （`result[h-1-i][w-1-j] = g[i][j]`）。`rotate90` 2回適用と同じで、2回適用すると元に戻る
- `transpose(g)`: 転置した w行h列のグリッドを返す（`result[j][i] = g[i][j]`）。
  `flip_v(rotate90(g))` と同じで、2回適用すると元に戻る
- `flip_h(g)`: 左右反転（`result[i][j] = g[i][w-1-j]`）。サイズは変わらない
- `flip_v(g)`: 上下反転（`result[i][j] = g[h-1-i][j]`）。サイズは変わらない
- いずれも `g` は空でない矩形グリッド（全行の長さが揃っている）を前提とする。
  空グリッドやジャグ配列のチェックは行わない
- `rotate90` と `flip_h`（または `flip_v`）を組み合わせれば、回転4種×反転2種＝
  8種類（二面体群D4）の変換を網羅できる（回転・反転を許容した形状一致判定などに使う）
- 実装はグリッド型 `G` を丸ごとテンプレートにした1本で、`vector<vector<T>>` でも
  `vector<string>` でもそのまま渡せる（結果グリッドの構築は内部ヘルパー `make_grid<G>(h, w)` が
  行型に応じて行う）。グリッド問題は入力が文字列で来ることが多く、`vector<string>` のまま扱える

```cpp
VEC(string, S, h);   // 1行1文字列でグリッドを読む（基本はこちら）
S = rotate90(S);     // 反時計回りに90度回転
S = rotate90_cw(S);  // 時計回りに90度回転
S = rotate180(S);    // 180度回転
S = transpose(S);    // 転置
S = flip_h(S);       // 左右反転

VV(int, A, h, w);    // 数値グリッドは vector<vector<T>> 版で
A = transpose(A);
```

### グリッドのバウンディングボックス切り詰め

```cpp
template <class G, class B>
G trim_grid(const G &g, const B &background);
```

- `g` の中で `background` と異なる値を持つセルの最小矩形（バウンディングボックス）
  に切り詰めて返す
- 該当セルが1つも無ければ空のグリッド（`{}`、0行）を返す
- `rotate90`/`flip_h`/`flip_v` と組み合わせて、回転・反転のたびに余白を
  揃え直す用途を想定（形状比較の前処理など）
- 他のグリッド関数と同様、`vector<vector<T>>` でも `vector<string>` でも
  そのまま渡せる（`trim_grid(S, '.')`）

```cpp
VEC(string, S, h);
S = trim_grid(S, '.');           // '.' 以外を含む最小矩形に切り詰め
S = trim_grid(rotate90(S), '.'); // 回転してから切り詰め
```

---

## 6. Graph（重みなし / 重み付き）

### 重みなしグラフ

```cpp
struct Graph
{
    int n;
    vector<vector<int>> g;

    Graph(int n = 0);
    void add_edge(int u, int v, bool undirected = true);
    vector<int> &operator[](int i);
    const vector<int> &operator[](int i) const;
};
```

使用例:

```cpp
Graph G(n);
G.add_edge(u, v);        // 無向
G.add_edge(u, v, false); // 有向

for (int to : G[u]) {
    // ...
}
```

### 重み付きグラフ

```cpp
template <class W = long long>
struct WeightedGraph
{
    struct Edge
    {
        int to;
        W w;
    };

    int n;
    vector<vector<Edge>> g;

    WeightedGraph(int n = 0);
    void add_edge(int u, int v, W w, bool undirected = true);
    vector<Edge> &operator[](int i);
    const vector<Edge> &operator[](int i) const;
};
```

使用例:

```cpp
WeightedGraph<ll> WG(n);
WG.add_edge(u, v, cost);        // 無向
WG.add_edge(u, v, cost, false); // 有向

for (auto e : WG[u]) {
    int to = e.to;
    ll w = e.w;
    // ...
}
```

---

## 7. 比較関数の書き方

余り（`k > 0`）を使う例です。入力が正の数のみなら `a % k` をそのまま使えます。

`sort` 用（余り昇順、同じ余りなら値昇順）:

```cpp
int k = 5;
auto cmp_mod = [k](ll a, ll b) {
    if (a % k != b % k) return (a % k) < (b % k);
    return a < b;
};
sort(v.begin(), v.end(), cmp_mod);
```

`priority_queue` 用（top が「余りが小さいもの」）:

```cpp
int k = 5;
auto cmp_pq = [k](ll a, ll b) {
    if (a % k != b % k) return (a % k) > (b % k);
    return a > b;
};
priority_queue<ll, vector<ll>, decltype(cmp_pq)> pq(cmp_pq);
```

---

## 8. main 雛形

```cpp
int main()
{
    // ここにコードを書く
}
```

必要に応じて以下を先頭に追加:

```cpp
ios::sync_with_stdio(false);
cin.tie(nullptr);
```
