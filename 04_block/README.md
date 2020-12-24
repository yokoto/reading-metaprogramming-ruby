# Block

## Overview of 4.1 - 4.2.3

### ブロックの基本

ブロックは、波かっこまたはdo...endキーワードで定義できる。

ブロックを定義できるのはメソッドを呼び出すときだけで、メソッドに渡されると yield キーワードを使ってブロックをコールバックする。

また、ブロックは任意で引数を受け取ることができる。
ブロックは、最終行を評価した結果を返す。

```rb
def a_method(a, b)
  a + yield(a, b)
end

a_method(1, 2) { |x, y| (x + y) * 3 } # => 10
```

メソッドの内部では、 Kernel#block_given? メソッドを使ってブロックの有無を確認できる。
block_given? が false の時に yield を使うと、実行時エラーになる。

```rb
def a_method
  return yield if block_given?
  'ブロックがありません'
end

a_method # => "ブロックがありません"
a_method { "ブロックがあるよ！" } # => "ブロックがあるよ！"
```

## Overview of 4.3 - 4章終わりまで

### ブロックはクロージャ

ブロックを定義すると、その時点でその場所にあるローカル変数、インスタンス変数、selfといったコードの集まりと **束縛** を取得する。

下記の例では、メソッドにある束縛はブロックからは見えないため、メソッドの束縛ではなく、ブロックが定義されたときの束縛が包み込まれる。

```rb
def my_method
  x = "Goodbye"
  yield("cruel")
end

x = "Hello"
my_method { |y| "#{x}, #{y} world" } # => "Hello, cruel world"
```

下記の例では、ブロックの中で新しい束縛を定義している。
ブロックの中で定義された束縛は、ブロックが終了した時点で消える。

上記の特性から、ブロックはクロージャであると言われる。

```rb
def just_yield
  yield
end

top_level_variable = 1

just_yield do
  top_level_variable += 1
  local_to_block = 1 # 新しい束縛
end

top_level_variable # => 2
local_to_block #  => Error!
```
#### グローバル変数とトップレベルのインスタンス変数

グローバル変数はどのスコープからでもアクセスできる。

```rb
def a_scope
  $var = "some value"
end

def another_scope
  $var
end

a_scope
another_scope # => "some value"
```

また、グローバル変数の代わりにトップレベルのインスタンス変数を使うこともできる。
これはトップレベルにある main オブジェクトのインスタンス変数である。

```rb
@var = "トップレベルの変数@var"

def my_method
  @var
end

my_method # => "トップレベルの変数@var"
```

#### スコープゲート

プログラムがスコープを変えると、新しい束縛と置き換えられる。

プログラムがスコープを切り替えて、新しいスコープをオープンする3つのキーワードを、スコープゲートと呼ぶ。

* クラス定義（ class ）
* モジュール定義（ module ）
* メソッド（ def ）

#### スコープのフラット化

スコープゲートを超えて束縛を渡すような難しい局面に遭遇することがある。

```rb
my_var = "成功"

class MyClass
  # my_var をここに表示したい...

  def my_method
    # ...ここにも表示したい
  end
end
```

スコープゲートをメソッド呼び出しに変えると、他のスコープの変数が見えるようになる。
これを、**入れ子構造のレキシカルスコープ** または **スコープのフラット化** と呼ぶ。
2つのスコープを一緒の場所に押し込めて、変数を共有する魔術を **フラットスコープ** と呼ぶ。

下記の例では、classのスコープを通り抜けて my_var を持ち運んでいる。

```rb
my_var = "成功"

MyClass = Class.new do
  # これで my_var を表示できる
  puts "クラス定義のなかは#{my_var}！"

  def my_method
    # ...
  end
end
```

下記の例では、defのスコープゲートを越えて my_var を渡している。

```rb
my_var = "成功"

MyClass = Class.new do
  puts "クラス定義のなかは#{my_var}！"

  define_method :my_method do
    "メソッド定義のなかも#{my_var}！"
  end
end

puts MyClass.new.my_method
# => クラス定義のなかは成功！
# メソッド定義のなかも成功！
```

#### スコープの共有

複数のメソッドで変数を共有したいが、その他からは見えないようにするために、すべてのメソッドを同じフラットスコープに定義する方法を、**共有スコープ** と呼ぶ。

```rb
def define_methods
  shared = 0

  Kernel.send :define_method, :counter do
    shared
  end

  Kernel.send :define_method, :inc do |x|
    shared += x
  end
end

define_methods

counter # => 0
inc(4)
counter # => 4
```

#### クロージャのまとめ

* スコープゲートを飛び越えて、現在の環境にある束縛を包み込み、持ち運びたいときはスコープが使える。
  * スコープゲートをメソッド呼び出しで置き換え、現在の束縛をクロージャで包み、そのクロージャをメソッドに渡すことができる。
* フラットスコープへの置き換え
  * class -> Class.new
  * module -> Module.new
  * def Module.define_method
* 共有スコープ
  * 同じフラットスコープに複数のメソッドを定義して、スコープゲートで守り、束縛を共有すること。

### instance_eval


### 呼び出し可能オブジェクト

#### Proc

#### lambda

### ドメイン特化言語を書く

