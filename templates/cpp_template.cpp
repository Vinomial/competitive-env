// ライブラリ: https://github.com/Vinomial/cp-library
#include <bits/stdc++.h>
using namespace std;

using ll = long long;
using ld = long double;
using i128 = __int128_t;
using u32 = uint32_t;
using u64 = uint64_t;
using u128 = __uint128_t;

// for文の短縮マクロ
#define rep0(i, n) for (int i = 0; i < (int)(n); ++i)
#define rep(i, a, b) for (int i = (int)(a); i < (int)(b); ++i)
#define rrep(i, a, b) for (int i = (int)(a); i > (int)(b); --i)
#define srep(i, a, b, step) \
    for (long long i = (a); (step) > 0 ? i < (b) : i > (b); i += (step))

// コンテナ操作の短縮マクロ
#define all(v) (v).begin(), (v).end()

template <class C>
constexpr bool is_sorted_container = false;
template <class T, class A>
constexpr bool is_sorted_container<set<T, less<T>, A>> = true;
template <class T, class A>
constexpr bool is_sorted_container<multiset<T, less<T>, A>> = true;

template <class C>
auto MIN(const C &c)
{
    if constexpr (is_sorted_container<C>)
        return *c.begin();
    else
        return *min_element(c.begin(), c.end());
}

template <class C>
auto MAX(const C &c)
{
    if constexpr (is_sorted_container<C>)
        return *c.rbegin();
    else
        return *max_element(c.begin(), c.end());
}

// よく使う定数
constexpr int INF = (1 << 29);
constexpr ll INFLL = (1LL << 60);
constexpr ll MOD = 998244353;
constexpr ll MOD2 = 1000000007;

// 型ごとにread/printを拡張した入出力ヘルパー
namespace fastio
{
    // 入力
    template <class T>
    void read(T &x) { cin >> x; }

    inline void read(i128 &x)
    {
        string s;
        cin >> s;
        bool neg = false;
        size_t i = 0;
        if (!s.empty() && (s[0] == '-' || s[0] == '+'))
        {
            neg = (s[0] == '-');
            i = 1;
        }
        u128 v = 0;
        for (; i < s.size(); i++)
            v = v * 10 + (s[i] - '0');
        if (neg)
            x = (v == 0) ? 0 : -i128(v - 1) - 1;
        else
            x = i128(v);
    }

    inline void read(u128 &x)
    {
        string s;
        cin >> s;
        size_t i = (!s.empty() && s[0] == '+') ? 1 : 0;
        u128 v = 0;
        for (; i < s.size(); i++)
            v = v * 10 + (s[i] - '0');
        x = v;
    }

    template <class A, class B>
    void read(pair<A, B> &p)
    {
        read(p.first);
        read(p.second);
    }

    template <size_t I = 0, class... Ts>
    inline enable_if_t<I == sizeof...(Ts)> read_tuple(tuple<Ts...> &) {}
    template <size_t I = 0, class... Ts>
        inline enable_if_t < I<sizeof...(Ts)> read_tuple(tuple<Ts...> &t)
    {
        read(get<I>(t));
        read_tuple<I + 1>(t);
    }
    template <class... Ts>
    void read(tuple<Ts...> &t) { read_tuple(t); }

    template <class T, size_t N>
    void read(array<T, N> &a)
    {
        for (auto &x : a)
            read(x);
    }
    template <class T>
    void read(vector<T> &v)
    {
        for (auto &x : v)
            read(x);
    }
    template <class T>
    void read(deque<T> &v)
    {
        for (auto &x : v)
            read(x);
    }

    template <class T, class Compare = less<T>, class Alloc = allocator<T>>
    set<T, Compare, Alloc> read_set(size_t n)
    {
        set<T, Compare, Alloc> s;
        for (size_t i = 0; i < n; i++)
        {
            T x;
            read(x);
            s.insert(x);
        }
        return s;
    }

    template <class T, class Compare = less<T>, class Alloc = allocator<T>>
    multiset<T, Compare, Alloc> read_multiset(size_t n)
    {
        multiset<T, Compare, Alloc> s;
        for (size_t i = 0; i < n; i++)
        {
            T x;
            read(x);
            s.insert(x);
        }
        return s;
    }

    template <class... Ts>
    void read_cols(size_t n, vector<Ts> &...vs)
    {
        (vs.resize(n), ...);
        for (size_t i = 0; i < n; i++)
            (read(vs[i]), ...);
    }

    template <class Head, class... Tail>
    void read(Head &head, Tail &...tail)
    {
        read(head);
        if constexpr (sizeof...(Tail))
            read(tail...);
    }

    inline string to_decimal_string(u128 x)
    {
        if (x == 0)
            return "0";
        string s;
        while (x > 0)
        {
            s.push_back(char('0' + x % 10));
            x /= 10;
        }
        reverse(s.begin(), s.end());
        return s;
    }

    inline string to_decimal_string(i128 x)
    {
        if (x < 0)
        {
            u128 y = u128(-(x + 1)) + 1;
            return "-" + to_decimal_string(y);
        }
        return to_decimal_string(u128(x));
    }

    inline void wt(i128 x) { cout << to_decimal_string(x); }
    inline void wt(u128 x) { cout << to_decimal_string(x); }

    // 基本型
    template <class T>
    void wt(const T &x)
    {
        if constexpr (requires { x.val(); })
        {
            wt(x.val());
        }
        else
        {
            cout << x;
        }
    }

    // 小数は小数点以下15桁で固定出力
    inline void wt(float x) { cout << fixed << setprecision(15) << x; }
    inline void wt(double x) { cout << fixed << setprecision(15) << x; }
    inline void wt(long double x) { cout << fixed << setprecision(15) << x; }

    // 文字列系
    inline void wt(const char *s) { cout << s; }
    inline void wt(const string &s) { cout << s; }

    // pair
    template <class A, class B>
    void wt(const pair<A, B> &p)
    {
        wt(p.first);
        cout << ' ';
        wt(p.second);
    }

    // tuple
    template <size_t I = 0, class... Ts>
    inline enable_if_t<I == sizeof...(Ts)> wt_tuple(const tuple<Ts...> &) {}
    template <size_t I = 0, class... Ts>
        inline enable_if_t < I<sizeof...(Ts)> wt_tuple(const tuple<Ts...> &t)
    {
        if (I)
            cout << ' ';
        wt(get<I>(t));
        wt_tuple<I + 1>(t);
    }
    template <class... Ts>
    void wt(const tuple<Ts...> &t) { wt_tuple(t); }

    template <class T>
    void wt(const set<T> &s);
    template <class T>
    void wt(const multiset<T> &s);
    template <class T>
    void wt(const unordered_set<T> &s);
    template <class K, class V>
    void wt(const map<K, V> &m);
    template <class K, class V>
    void wt(const unordered_map<K, V> &m);
    template <class T, class Container, class Compare>
    void wt(const priority_queue<T, Container, Compare> &q);

    // array / vector / deque
    template <class T, size_t N>
    void wt(const array<T, N> &a)
    {
        for (size_t i = 0; i < N; i++)
        {
            if (i)
                cout << ' ';
            wt(a[i]);
        }
    }
    template <class T>
    void wt(const vector<T> &v)
    {
        for (size_t i = 0; i < v.size(); i++)
        {
            if (i)
                cout << ' ';
            wt(v[i]);
        }
    }
    template <class T>
    void wt(const vector<vector<T>> &v)
    {
        for (size_t i = 0; i < v.size(); i++)
        {
            if (i)
                cout << '\n';
            wt(v[i]);
        }
    }
    template <class T>
    void wt(const deque<T> &v)
    {
        for (size_t i = 0; i < v.size(); i++)
        {
            if (i)
                cout << ' ';
            wt(v[i]);
        }
    }
    template <class T, class Container, class Compare>
    void wt(const priority_queue<T, Container, Compare> &q)
    {
        auto qq = q;
        bool first = true;
        while (!qq.empty())
        {
            if (!first)
                cout << ' ';
            first = false;
            wt(qq.top());
            qq.pop();
        }
    }

    // set / multiset / unordered_set
    template <class T>
    void wt(const set<T> &s)
    {
        bool first = true;
        for (auto &x : s)
        {
            if (!first)
                cout << ' ';
            first = false;
            wt(x);
        }
    }
    template <class T>
    void wt(const multiset<T> &s)
    {
        bool first = true;
        for (auto &x : s)
        {
            if (!first)
                cout << ' ';
            first = false;
            wt(x);
        }
    }
    template <class T>
    void wt(const unordered_set<T> &s)
    {
        bool first = true;
        for (auto &x : s)
        {
            if (!first)
                cout << ' ';
            first = false;
            wt(x);
        }
    }

    // map / unordered_map
    template <class K, class V>
    void wt(const map<K, V> &m)
    {
        bool first = true;
        for (auto &kv : m)
        {
            if (!first)
                cout << " | ";
            first = false;
            wt(kv.first);
            cout << ':';
            wt(kv.second);
        }
    }
    template <class K, class V>
    void wt(const unordered_map<K, V> &m)
    {
        bool first = true;
        for (auto &kv : m)
        {
            if (!first)
                cout << " | ";
            first = false;
            wt(kv.first);
            cout << ':';
            wt(kv.second);
        }
    }

    // 出力本体
    void print() { cout << '\n'; }

    template <class Head, class... Tail>
    void print(const Head &head, const Tail &...tail)
    {
        wt(head);
        if (sizeof...(Tail))
            cout << ' ';
        print(tail...);
    }

    inline void yesno(bool cond) { cout << (cond ? "Yes" : "No") << '\n'; }

} // namespace fastio

// 頻出のI/O関数だけ名前空間から取り出す
using fastio::print;
using fastio::read;
using fastio::read_cols;
using fastio::read_multiset;
using fastio::read_set;
using fastio::yesno;

// 宣言+入力を1行で書くマクロ
#define INT(...)     \
    int __VA_ARGS__; \
    read(__VA_ARGS__)
#define LL(...)     \
    ll __VA_ARGS__; \
    read(__VA_ARGS__)
#define U32(...)     \
    u32 __VA_ARGS__; \
    read(__VA_ARGS__)
#define U64(...)     \
    u64 __VA_ARGS__; \
    read(__VA_ARGS__)
#define STR(...)        \
    string __VA_ARGS__; \
    read(__VA_ARGS__)
#define CHAR(...)     \
    char __VA_ARGS__; \
    read(__VA_ARGS__)
#define DBL(...)        \
    double __VA_ARGS__; \
    read(__VA_ARGS__)
#define LD(...)     \
    ld __VA_ARGS__; \
    read(__VA_ARGS__)
#define I128(...)     \
    i128 __VA_ARGS__; \
    read(__VA_ARGS__)
#define U128(...)     \
    u128 __VA_ARGS__; \
    read(__VA_ARGS__)
#define VEC(type, name, size) \
    vector<type> name(size);  \
    read(name)
#define DEQ(type, name, size) \
    deque<type> name(size);   \
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
#define VV(type, name, h, w)                       \
    vector<vector<type>> name(h, vector<type>(w)); \
    read(name)
#define VEC0(type, name, size) \
    vector<type> name(size)
#define VV0(type, name, h, w) \
    vector<vector<type>> name(h, vector<type>(w))
#define VECI(type, name, size, init) \
    vector<type> name(size, init)
#define VVI(type, name, h, w, init) \
    vector<vector<type>> name(h, vector<type>(w, init))
#define VVV0(type, name, d1, d2, d3) \
    vector<vector<vector<type>>> name(d1, vector<vector<type>>(d2, vector<type>(d3)))
#define VVVI(type, name, d1, d2, d3, init) \
    vector<vector<vector<type>>> name(d1, vector<vector<type>>(d2, vector<type>(d3, init)))

template <class C, class T>
auto ge_it(const C &c, const T &x)
{
    return c.lower_bound(x);
}

template <class C, class T>
auto le_it(const C &c, const T &x)
{
    auto it = c.upper_bound(x);
    if (it == c.begin())
        return c.end();
    --it;
    return it;
}

template <class C, class T>
typename C::value_type ge_val(const C &c, const T &x)
{
    auto it = ge_it(c, x);
    if (it == c.end())
        throw out_of_range("ge_val: no element >= x");
    return *it;
}

template <class C, class T>
typename C::value_type le_val(const C &c, const T &x)
{
    auto it = le_it(c, x);
    if (it == c.end())
        throw out_of_range("le_val: no element <= x");
    return *it;
}

template <class T, class Compare, class Alloc>
bool discard_one(set<T, Compare, Alloc> &s, const T &x)
{
    return s.erase(x) > 0;
}

template <class T, class Compare, class Alloc>
bool discard_one(multiset<T, Compare, Alloc> &s, const T &x)
{
    auto it = s.find(x);
    if (it == s.end())
        return false;
    s.erase(it); // erase only one
    return true;
}

template <class T, class Compare, class Alloc>
int discard_all(set<T, Compare, Alloc> &s, const T &x)
{
    return (int)s.erase(x); // 0 or 1
}

template <class T, class Compare, class Alloc>
int discard_all(multiset<T, Compare, Alloc> &s, const T &x)
{
    return (int)s.erase(x); // remove all x
}

template <class T, class U>
int bisect_left(const vector<T> &v, const U &x)
{
    return int(lower_bound(v.begin(), v.end(), x) - v.begin());
}

template <class T, class U>
int bisect_right(const vector<T> &v, const U &x)
{
    return int(upper_bound(v.begin(), v.end(), x) - v.begin());
}

template <class T, class U>
auto floor_div(T a, U b)
{
    auto q = a / b, r = a % b;
    return q - ((r != 0) && ((r < 0) != (b < 0)));
}

template <class T, class U>
auto ceil_div(T a, U b)
{
    auto q = a / b, r = a % b;
    return q + ((r != 0) && ((r < 0) == (b < 0)));
}

template <class T, class U>
bool chmin(T &x, const U &y)
{
    if (y < x)
    {
        x = (T)y;
        return true;
    }
    return false;
}

template <class T, class U>
bool chmax(T &x, const U &y)
{
    if (x < y)
    {
        x = (T)y;
        return true;
    }
    return false;
}

template <class T>
T isqrt(T n)
{
    T r = (T)sqrtl((long double)n);
    while (i128(r + 1) * (r + 1) <= (i128)n)
        r++;
    while (i128(r) * r > (i128)n)
        r--;
    return r;
}

template <class T>
bool is_square(T n)
{
    T r = isqrt(n);
    return i128(r) * r == (i128)n;
}

template <class T>
T ipow(T a, long long e)
{
    T r = 1;
    while (e > 0)
    {
        if (e & 1)
            r *= a;
        a *= a;
        e >>= 1;
    }
    return r;
}

// argsort(v): vを昇順に見たときのindex列
// apply_order(order, vs...): order[i]番目の要素を新しいi番目にする
template <class T, class Alloc, class Compare = less<T>>
vector<int> argsort(const vector<T, Alloc> &v, Compare comp = Compare())
{
    int n = (int)v.size();
    vector<int> order(n);
    iota(all(order), 0);
    stable_sort(all(order), [&](int i, int j)
                { return comp(v[i], v[j]); });
    return order;
}

template <class T, class Alloc>
void apply_order_one(const vector<int> &order, vector<T, Alloc> &v)
{
    assert(order.size() == v.size());
    vector<T, Alloc> res(v.get_allocator());
    res.reserve(v.size());
    for (int i : order)
    {
        assert(0 <= i && i < (int)v.size());
        res.push_back(v[i]);
    }
    v.swap(res);
}

template <class... Vecs>
void apply_order(const vector<int> &order, Vecs &...vs)
{
    (apply_order_one(order, vs), ...);
}

template <class Key, class Alloc, class... Vecs>
void sort_by_key(vector<Key, Alloc> &key, Vecs &...vs)
{
    vector<int> order = argsort(key);
    apply_order(order, key, vs...);
}

template <class C>
C reversed(C c)
{
    reverse(c.begin(), c.end());
    return c;
}

template <class T>
T sum(const vector<T> &v)
{
    return accumulate(v.begin(), v.end(), T(0));
}

template <class T>
ld sum_ld(const vector<T> &v)
{
    return accumulate(v.begin(), v.end(), 0.0L);
}

template <class T, class AllocA, class AllocB>
vector<T, AllocA> concat(const vector<T, AllocA> &a, const vector<T, AllocB> &b)
{
    vector<T, AllocA> res;
    res.reserve(a.size() + b.size());
    res.insert(res.end(), a.begin(), a.end());
    res.insert(res.end(), b.begin(), b.end());
    return res;
}

template <class T, class AllocA, class AllocB>
vector<T, AllocA> operator+(const vector<T, AllocA> &a, const vector<T, AllocB> &b)
{
    return concat(a, b);
}

template <class T, class AllocA, class AllocB>
vector<T, AllocA> &operator+=(vector<T, AllocA> &a, const vector<T, AllocB> &b)
{
    a.insert(a.end(), b.begin(), b.end());
    return a;
}

template <class T, size_t N, size_t M>
array<T, N + M> concat(const array<T, N> &a, const array<T, M> &b)
{
    array<T, N + M> res{};
    copy(a.begin(), a.end(), res.begin());
    copy(b.begin(), b.end(), res.begin() + N);
    return res;
}

// 区切り文字付きjoinヘルパー
template <class It>
string join(It first, It last, const string &sep)
{
    ostringstream oss;
    bool first_elem = true;
    for (auto it = first; it != last; ++it)
    {
        if (!first_elem)
            oss << sep;
        first_elem = false;
        oss << *it;
    }
    return oss.str();
}

inline string join(const vector<string> &v, const string &sep)
{
    size_t total = 0;
    if (!v.empty())
        total = (v.size() - 1) * sep.size();
    for (const auto &s : v)
        total += s.size();
    string res;
    res.reserve(total);
    for (size_t i = 0; i < v.size(); ++i)
    {
        if (i)
            res += sep;
        res += v[i];
    }
    return res;
}

inline string join(const string &s, const string &sep)
{
    if (s.empty())
        return "";
    string res;
    if (!sep.empty())
        res.reserve(s.size() + (s.size() - 1) * sep.size());
    for (size_t i = 0; i < s.size(); ++i)
    {
        if (i)
            res += sep;
        res += s[i];
    }
    return res;
}

template <class C>
string join(const C &c, const string &sep)
{
    return join(c.begin(), c.end(), sep);
}

inline int count(const string &s, char c)
{
    return int(std::count(s.begin(), s.end(), c));
}

inline int count(const string &s, const string &t)
{
    if (t.empty())
        return int(s.size() + 1);
    int cnt = 0;
    size_t pos = 0;
    while (true)
    {
        pos = s.find(t, pos);
        if (pos == string::npos)
            break;
        ++cnt;
        pos += t.size(); // Python str.count と同じく重なりは数えない
    }
    return cnt;
}

inline string replace(string s, const string &from, const string &to)
{
    if (from.empty())
        return s;
    size_t pos = 0;
    while (true)
    {
        pos = s.find(from, pos);
        if (pos == string::npos)
            break;
        s.replace(pos, from.size(), to);
        pos += to.size();
    }
    return s;
}

inline string replace(string s, char from, char to)
{
    std::replace(s.begin(), s.end(), from, to);
    return s;
}

template <class C>
auto rle(const C &s)
{
    vector<pair<typename C::value_type, int>> res;
    for (const auto &x : s)
    {
        if (!res.empty() && res.back().first == x)
            res.back().second++;
        else
            res.push_back({x, 1});
    }
    return res;
}

constexpr int DX4[] = {1, 0, -1, 0};
constexpr int DY4[] = {0, 1, 0, -1};
constexpr int DX8[] = {1, 1, 0, -1, -1, -1, 0, 1};
constexpr int DY8[] = {0, 1, 1, 1, 0, -1, -1, -1};

inline bool in_grid(ll i, ll j, ll h, ll w)
{
    return 0 <= i && i < h && 0 <= j && j < w;
}

template <class G>
G make_grid(int h, int w)
{
    using Row = typename G::value_type;
    if constexpr (is_same_v<Row, string>)
        return G(h, string(w, ' '));
    else
        return G(h, Row(w));
}

template <class G>
G rotate90(const G &g)
{
    int h = (int)g.size();
    int w = (int)g[0].size();
    G res = make_grid<G>(w, h);
    for (int i = 0; i < h; i++)
        for (int j = 0; j < w; j++)
            res[w - 1 - j][i] = g[i][j];
    return res;
}

template <class G>
G rotate90_cw(const G &g)
{
    int h = (int)g.size();
    int w = (int)g[0].size();
    G res = make_grid<G>(w, h);
    for (int i = 0; i < h; i++)
        for (int j = 0; j < w; j++)
            res[j][h - 1 - i] = g[i][j];
    return res;
}

template <class G>
G rotate180(const G &g)
{
    G res(g);
    reverse(res.begin(), res.end());
    for (auto &row : res)
        reverse(row.begin(), row.end());
    return res;
}

template <class G>
G transpose(const G &g)
{
    int h = (int)g.size();
    int w = (int)g[0].size();
    G res = make_grid<G>(w, h);
    for (int i = 0; i < h; i++)
        for (int j = 0; j < w; j++)
            res[j][i] = g[i][j];
    return res;
}

template <class G>
G flip_h(const G &g)
{
    G res(g);
    for (auto &row : res)
        reverse(row.begin(), row.end());
    return res;
}

template <class G>
G flip_v(const G &g)
{
    G res(g);
    reverse(res.begin(), res.end());
    return res;
}

template <class G, class B>
G trim_grid(const G &g, const B &background)
{
    int h = (int)g.size();
    int w = (int)g[0].size();
    int min_i = h, max_i = -1, min_j = w, max_j = -1;
    for (int i = 0; i < h; i++)
    {
        for (int j = 0; j < w; j++)
        {
            if (g[i][j] != background)
            {
                min_i = min(min_i, i);
                max_i = max(max_i, i);
                min_j = min(min_j, j);
                max_j = max(max_j, j);
            }
        }
    }
    if (max_i < min_i)
        return {};

    G res = make_grid<G>(max_i - min_i + 1, max_j - min_j + 1);
    for (int i = min_i; i <= max_i; i++)
        for (int j = min_j; j <= max_j; j++)
            res[i - min_i][j - min_j] = g[i][j];
    return res;
}

struct Graph
{
    int n;
    vector<vector<int>> g;

    Graph(int n = 0) : n(n), g(n) {}

    void add_edge(int u, int v, bool undirected = true)
    {
        g[u].push_back(v);
        if (undirected)
            g[v].push_back(u);
    }

    vector<int> &operator[](int i) { return g[i]; }
    const vector<int> &operator[](int i) const { return g[i]; }
};

template <class W = long long>
struct WeightedGraph
{
    struct Edge
    {
        int to;
        W w;

        friend ostream &operator<<(ostream &os, const Edge &e)
        {
            return os << e.to << ':' << e.w;
        }
    };

    int n;
    vector<vector<Edge>> g;

    WeightedGraph(int n = 0) : n(n), g(n) {}

    void add_edge(int u, int v, W w, bool undirected = true)
    {
        g[u].push_back({v, w});
        if (undirected)
            g[v].push_back({u, w});
    }

    vector<Edge> &operator[](int i) { return g[i]; }
    const vector<Edge> &operator[](int i) const { return g[i]; }
};

int main()
{
    // ここにコードを書く
}
