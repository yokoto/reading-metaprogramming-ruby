# Block

## Overview of 4.1 - 4.3.4

### ブロックの基本

* メソッドを呼び出すときにだけ定義できる。
* メソッドに渡されると yield キーワードを使ってコールバックする。
* 任意で引数を受け取ることができる。
* 最終行を評価した結果を返す。
* Kernel#block_given? メソッドを使ってブロックの有無を確認できる。
* block_given? が false の時に yield を使うと、実行時エラーになる。

```rb
def a_method(a, b)
  a + yield(a, b)
end

a_method(1, 2) { |x, y| (x + y) * 3 } # => 10
```

```rb
def a_method
  return yield if block_given?
  'ブロックがありません'
end

a_method # => "ブロックがありません"
a_method { "ブロックがあるよ！" } # => "ブロックがあるよ！"
```

### ブロックはクロージャ

* ブロックは定義された時点で、その場の（ローカル変数、インスタンス変数、selfといった） **束縛** を取得する。
* ブロックの中で定義された束縛は、ブロックが終了した時点で消える。
  * 上記の特性から、ブロックはクロージャであると言われる。

下記の例では、メソッドにある束縛はブロックからは見えないため、  
メソッドの束縛ではなく、ブロックが定義されたときの束縛が包み込まれる。

```rb
def my_method
  x = "Goodbye"
  yield("cruel")
end

x = "Hello"
my_method { |y| "#{x}, #{y} world" } # => "Hello, cruel world"
```

下記の例では、ブロックの中で新しい束縛を定義している。  
local_to_block はトップレベルのスコープで定義されていないため、エラーになる。

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

### グローバル変数とトップレベルのインスタンス変数

どのスコープからでもアクセスできる変数として、以下の2つがある。

* グローバル変数
* トップレベル（main オブジェクト）のインスタンス変数

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

```rb
@var = "トップレベルの変数@var"

def my_method
  @var
end

my_method # => "トップレベルの変数@var"
```

### スコープゲート

プログラムがスコープを変えると、新しい束縛と置き換えられる。  

プログラムがスコープを切り替えて、新しいスコープをオープンする3つのキーワードを、**スコープゲート** と呼ぶ。

* クラス定義（ class ）
* モジュール定義（ module ）
* メソッド（ def ）

### スコープのフラット化

スコープゲートを超えて束縛を渡すような難しい局面に遭遇することがある。  

スコープゲートをメソッド呼び出しに変えると、他のスコープの変数が見えるようになる。  
これを、**入れ子構造のレキシカルスコープ** または **スコープのフラット化** と呼ぶ。  
2つのスコープを一緒の場所に押し込めて、変数を共有する魔術を **フラットスコープ** と呼ぶ。  

下記の例では、classのスコープを通り抜けて my_var を持ち運ベるようにコードを変更している。


```rb
my_var = "成功"

class MyClass
  # my_var をここに表示したい...

  def my_method
    # ...ここにも表示したい
  end
end
```

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

下記の例では、def のスコープゲートを越えて my_var を渡している。

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

### スコープの共有

複数のメソッドで変数を共有したいが、その他からは見えないようにするために、  
すべてのメソッドを同じフラットスコープに定義する方法を、**共有スコープ** と呼ぶ。

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

### クロージャのまとめ

* スコープゲートを飛び越えて、現在の環境にある束縛を包み込み、持ち運びたいときはスコープが使える。
  * スコープゲートをメソッド呼び出しで置き換え、現在の束縛をクロージャで包み、そのクロージャをメソッドに渡すことができる。
* フラットスコープへの置き換え
  * class -> Class.new
  * module -> Module.new
  * def -> Module.define_method
* 共有スコープ
  * 同じフラットスコープに複数のメソッドを定義して、スコープゲートで守り、束縛を共有すること。

## Overview of 4.4 - 4.4.2

### instance_eval

* BasicObject#instance_eval は、オブジェクトのコンテキストでブロックを評価する。
* 渡したブロックはレシーバを self にしてから評価される
* レシーバの private メソッドやインスタンス変数にもアクセスできる。
* 他のブロックと同じように、 instance_eval を定義したときの束縛も見える。

instance_eval に渡したブロックのことを **コンテキスト探査機** と呼ぶ。

### instance_exec

* instance_eval とわずかに異なり、ブロックに引数を渡すことができる。

```rb
class C
  def initialize
    @x = 1
  end
end

class D
  def twisted_method
    @y= 2
    C.new.instance_eval { "@x: #{@x}, @y: #{@y}" }
  end
end

D.new.twisted_method # => "@x: 1, @y: "
```

```rb
class D
  def twisted_method
    @y = 2
    C.new.instance_exec(@y) { |y| "@x: #{@x}, @y: #{y}" }
  end
end
D.new.twisted_method # => "@x: 1, @y: 2"
```

### カプセル化の破壊

コンテキスト探査機を実際に使うのは、 irb からオブジェクトの中身を見たい時や、テストの時。

#### Padrinoの例

Logger クラスは、自身のインスタンス変数に設定を格納しており、
ここでは、 @log_static が true であれば静的ファイルへのアクセスを記録する。

instance_eval を使えば、わざわざ新しいロガーを作成して設定するのではなく、
コンテキスト探査機で既存のアプリケーションロガーの中身を見てから、その設定を変更することができる。

```rb
describe "PadrinoLogger" do
  context 'for logger functionality' do
    context "static asset logging" do
      should 'not log static assets by default' do
        # ...
        get "/images/something.png"
        assert_equal "Foo", body
        assert_match "", Padrino.logger.log.string
      end

      should 'allow turning on static assets logging' do
        Padrino.logger.instance_eval { @log_static = true }
        # ...
        get "/images/something.png"
        assert_equal "Foo", body
        assert_match /GET/, Padrino.logger.log.string
        Padrino.logger.instance_eval { @log_static = false }
      end
    end

    # ...
```

### クリーンルーム

ブロックを評価するためだけに生成されたオブジェクトを、 **クリーンルーム** と呼ぶ。

クリーンルームとして使うには、メソッドがほとんど存在しないブランクスレートであるという理由から、
BasicObjectのインスタンスが最適。

## Overview of 4.5 - 4章終わりまで

### Procオブジェクト

* Proc クラスは、ブロックをオブジェクトにしたもの。
* Proc.new にブロックを渡すことで Proc を生成する。
* Proc#call でオブジェクトになったブロックを **遅延評価** する。
* 以下の2つのカーネルメソッドによっても生成することができる。
  * lambda
  * proc 

```rb
inc = Proc.new { |x| x + 1 }
# いろんなコード...
inc.call(2) # => 3
```

```rb
dec = lambda { |x| x - 1 }
dec.class # => Proc
dec.call(2) # => 1
```

以下の二つのコードは同じ意味。

```rb
p = ->(x) { x + 1 }
p = lambda { |x| x + 1 }
```

### ＆修飾

* ブロックは、メソッドに渡す無名引数のようなもの。
* 通常はメソッドの中で yield を使って実行する。
* 以下のケースでは **＆修飾** を使う。
  * 他のメソッドにブロックを渡したい時
    * 引数列の最後に置いて、名前の前に ＆ を付ける。
  * ブロックを Proc に変換したい時
  * Proc をブロックに戻したい時

```rb
def math(a, b)
  yield(a, b)
end

def do_math(a, b, &operation)
  math(a, b, &operation)
end

do_math(2, 3) { |x, y| x * y } # => 6
```

### 「Proc」対「lambda」

* lambdaの方がメソッドに似ていて直感的。
  * return を呼ぶと終了してくれる。
  * 項数に厳しい。

#### 1. return キーワードの意味

* lambda の場合、単に戻るだけ。
* Proc の場合、 Procが定義されたスコープから戻る。

```rb
def double(callable_object)
  callable_object.call * 2
end

1 = lambda { return 10 }
double(1) # => 20
```

```rb
def another_double
  p = Proc.new { return 10 } # ここから戻る。
  result = p.call
  return result * 2 # ここまで来ない！
end

another_double # => 10
```

以下のプログラムでは、p が定義されたトップレベルのスコープからは戻れないため、失敗する。

```rb
def double(callable_object)
  callable_object.call * 2
end

p = Proc.new { return 10 }
double(p) # => LocalJumpError
```

明示的な return を使わないようにし、このようなミスを回避する必要がある。

```rb
p = Proc.new { 10 }
double(p) # => 20
```

#### 2. 引数のチェック方法

* Proc の場合、多い引数を切り落とし、足りない引数には nil を割り当てる。
* lambda の場合、違った項数で呼び出すと、ArgumentError になる。

### Methodオブジェクト

* Method オブジェクト
  * Object#method を呼び出すと、メソッドそのもの（Method オブジェクト）を取得できる。
  * Method#call を使って実行できる。
  * Ruby 2.1~ Kernel#singelton_method を呼び出すと、特異メソッドの名前から Method オブジェクトを取得できる。
  * ブロックや lambda に似ている
    * lambda
      * 定義されたスコープで評価される（クロージャ）
    * Method
      * 所属するオブジェクトのスコープで評価される

```rb
class MyClass
  def initialize(value)
    @x = value
  end

  def my_method
    @x
  end
end

object = MyClass.new(1)
m = object.method :my_method # Method オブジェクトを取得
m.call # => 1
```

### UnboundMethod

* UnboundMethod
  * 特殊なケースでのみ使用する。
  * 直接呼び出すことができない、元のクラスやモジュールから引き離されたメソッドのようなもの。
  * Module#instance_method や Method#unbind により生成する。
  * UnboundMethod#bind によりレシーバを割り当てた Method オブジェクトを作る（オブジェクトに束縛する）ことができる。

https://docs.ruby-lang.org/ja/latest/class/UnboundMethod.html

```rb
module MyModule
  def my_method
    42
  end
end

unbound = MyModule.instance_method(:my_method)
unbound.class # => UnboundMethod
```

UnboundMethod は元のクラスと同じクラス（またはサブクラス）のオブジェクトにしか束縛できないため、以下の例のように、Module#define_method に渡すことで束縛する。

```rb
String.send :define_method, :another_method, unbound

"abc".another_method # => 42
```

String の define_method は private メソッドのため、動的メソッドを使って呼び出す。

### Active Supportの例

ActiveSupport には「自動読み込み」システムがあり、定数を使った時に、それが定義されたファイルを自動的に読み込むクラスやモジュールがある。  
例えば、標準の Kernle#load メソッドを再定義する Lodabale というモジュールが含まれている。  

クラスが Lodable をインクルードした時に、 Lodable#load が   Kernel#load よりも継承チェーンの下にあれば、 load の呼び出しは  Lodable#load にたどり着く。
インクルードした Lodable を削除、つまり通常の Kernel#load を使いたくなった場合、下記のようなコードによってそれを行う。

> https://docs.ruby-lang.org/ja/latest/method/Module/i/class_eval.html
> モジュールのコンテキストで文字列 expr またはモジュール自身をブロックパラメータとするブロックを評価してその結果を返します。
> モジュールのコンテキストで評価するとは、実行中そのモジュールが self になるということです。つまり、そのモジュールの定義式の中にあるかのように実行されます。
> ただし、ローカル変数は module_eval/class_eval の外側のスコープと共有します。

その結果、 MyClass#load が Kernel#load と同等になる。
これは、Lodable の load メソッドをオーバーライドしている。

```rb
module Lodable
  def self.exclude_from(base)
    base.class_eval { define_method(:load, Kernel.instance_method(:load)) }
  end

  # ...
end
```

Lodable.exclude_from(MyClass) を呼び出すと、上記のコードが instance_method を呼び出して、元の Kernel#load を UnboundMethod として取得する。  
そして、（コンテキスト探査機 class_eval を使って）MyClass にその新しい load メソッドを定義する。  

UnboundMethod によって、Kernel#load と MyClass#load はよく似ているが、Kernel#load と Lodable#load は全く呼び出されない。  

### 呼び出し可能オブジェクトのまとめ

呼び出し可能オブジェクトとは、評価ができて、スコープを持ち運べるコードのこと。  
呼び出し可能オブジェクトになれるのは以下。  

* ブロック（「オブジェクト」ではないが「呼び出し可能」）：定義されたスコープで評価される。
* Proc：Proc クラスのオブジェクト。ブロックのように、定義されたスコープで評価される。
* lambda：これも Proc クラスのオブジェクトだが、通常の Procとは微妙に異なる。ブロックや Proc と同じくクロージャであり、定義されたスコープで評価される。
* メソッド：オブジェクトに束縛され、オブジェクトのスコープで評価される。オブジェクトのスコープから引き離し、他のオブジェクトに束縛することもできる。

呼び出し可能オブジェクトは、種類によって動作に微妙な違いがある。  
メソッドと lambda では、 return で呼び出し可能オブジェクトから戻る。  
一方、Proc とブロックでは、呼び出し可能オブジェクトの元のコンテキストから戻る。  
また、呼び出し時の項数の違いに対する反応も異なる。メソッドは厳密である。  
lambda もほぼ厳密である。Proc とブロックは寛容である。  
こうした違いはあるにせよ、Proc.new 、 Method#to_proc 、 ＆修飾などを使って、ある呼び出し可能オブジェクトから別の呼び出し可能オブジェクトに変換することができる。  

### ドメイン特化言語を書く

#### Redflag の作成

Redflag プロジェクトは、営業部で様々なイベントが発生した時にメッセージを送信するユーティリティ。
営業部の人がイベントを定義できる簡単なドメイン 特化言語（DSL）を書く。

Redflags DSL

```rb
# blocks/redflag_3/events.rb
setup do
  puts "空の高さを設定"
  @sky_height = 100
end

setup do
  puts "山の高さを設定"
  @mountains_height = 200
end

event "空が落ちてくる" do
  @sky_height < 300
end

event "空が近づいている" do
  @sky_height < @mountains_height
end

event "もうダメだ...手遅れ" do
  @sky_height < 0
end

# => 空の高さを設定
#    山の高さを設定
#    ALRET: 空が落ちてくる
#    空の高さを設定
#    山の高さを設定
#    ALRET: 空が近づいている
#    空の高さを設定
#    山の高さを設定
# ...
```

```rb
# blocks/redflag_4/redflag.rb
lambda {
  setups = []
  events = []

  Kernel.send :define_method, :setup do |&block|
    setups << block
  end

  Kernel.send :define_method, :event do |description, &block|
    events << {:description => description, :condition => block}
  end

  Kernel.send :define_method, :each_setup do |&block|
    setups.each do |setup|
      block.call setup
    end
  end

  Kernel.send :define_method, :each_event do |&block|
    events.each do |event|
      block.call event
    end
  end
}.call

load 'events.rb'

each_event do |event|
  env = Object.new
  each_setup do |setup|
    evn.instance_eval &setup
  end
  puts "ALERT: #{event[:description]}" if env.instance_eval &(event[:condition])
end
```

## まとめ

* スコープゲートとは、新しいスコープをオープンする3つのキーワードのこと。
  * class 、 module 、 def
* フラットスコープを使って、スコープを横断して束縛を見ることができる。
* フラットスコープへの置き換え
  * class -> Class.new
  * module -> Module.new
  * def -> Module.define_method
* 共有スコープとは、全てのメソッドを同じフラットスコープに定義する方法。
* コンテキスト探査機とは、オブジェクトのスコープでコードを実行する方法。
  * isntance_eval 、 instance_exec 、 class_eval
* クリーンルームとは、ブロックを評価するためだけに生成されたオブジェクトのこと。
  * 例: obj = Object.new、 ins = BasicObject.new
* ブロックとオブジェクト（Proc）は、＆修飾 によって相互に変換できる。
* メソッドとオブジェクト（Method や UnboundMethod）はModule#instance_method や Method#unbind 、 UnboundMethod#bind によって相互に変換することができる。
* 呼び出し可能オブジェクト（ブロック、Proc 、lambda）は、return キーワードの意味や引数のチェック方法について動作が異なり、評価されるスコープにおいて通常のメソッドと異なる。
