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

## Overview of 4.3 - 4.3.4

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

プログラムがスコープを切り替えて、新しいスコープをオープンする3つのキーワードを、**スコープゲート** と呼ぶ。

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
  * def -> Module.define_method
* 共有スコープ
  * 同じフラットスコープに複数のメソッドを定義して、スコープゲートで守り、束縛を共有すること。

## Overview of 4.4 - 4.4.2

### instance_eval

BasicObject#instance_eval は、オブジェクトのコンテキストでブロックを評価する。

渡したブロックはレシーバを self にしてから評価されるので、レシーバの private メソッドやインスタンス変数にもアクセスできる。
また、他のブロックと同じように、 instance_eval を定義したときの束縛も見える。

instance_eval に渡したブロックのことをコンテキスト探査機と呼ぶ。

#### instance_exec

インスタンス変数は self によって決まる。

下記の例では、instance_eval が self をレシーバに変更すると、呼び出し側のインスタンス変数 @y は C のインスタンス変数だと解釈され、 nil だと認識される。

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

@x と @y を同じスコープに入れるには、 instance_exec を使って @y の値をブロックに渡す。

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

Padrinoウェブフレームワークは、ウェブアプリケーションが扱うべきすべてのロギングを管理する Logger クラスを定義しており、 Logger クラスは、自身のインスタンス変数に設定を格納している。
例えば、 @log_static が true であれば、静的ファイルへのアクセスを記録する。

instance_eval を使えば、わざわざ新しいロガーを作成して設定するのではなく、コンテキスト探査機で既存のアプリケーションロガーの中身を見てから、その設定を変更することができる。

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

下記の例では、 クリーンルームである CleanRoom クラスに、ブロックから呼び出す current_temperature という便利なメソッドが用意されている。

```rb
class CleanRoom
  def current_temperature
    # ...
  end
end

clean_room = CleanRoom.new
clean_room.instance_eval do
  if current_temperature < 20
    # TODO: ジャケットを着る
  end
end
```

## Overview of 4.5 - 4章終わりまで

### 呼び出し可能オブジェクト

#### Procオブジェクト

Rubyの標準ライブラリに用意されている Proc クラスは、ブロックをオブジェクトにしたもの。

Proc.new にブロックを渡すことで Proc を生成し、
Proc#call でオブジェクトになったブロックを**遅延評価**する。

```rb
inc = Proc.new { |x| x + 1 }
# いろんなコード...
inc.call(2) # => 3
```

Procは、ブロックを Proc に変換する2つのカーネルメソッド lambda 、 proc によっても生成することができる。

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

#### ＆修飾

ブロックは、メソッドに渡す無名引数のようなもの。
通常は、メソッドの中で yield を使って実行するが、 yieldで足りないケースが2つある。

* 他のメソッドにブロックを渡したい時
* ブロックを Proc に変換したい時

引数列の最後に置いて、名前の前に ＆ の印をつけることで、
渡されたブロックを他のメソッドに渡すことができる。
逆に、Proc をブロックに戻したい場合にも、＆修飾を使う。

下記の例では、do_math メソッドに渡されたブロックを受け取って、それを Proc に変換している。
math メソッドを呼び出す時に Proc である operation に ＆ 修飾をつけて、
ブロックに変換してからメソッドに渡している。

```rb
def math(a, b)
  yield(a, b)
end

def do_math(a, b, &operation)
  math(a, b, &operation)
end

do_math(2, 3) { |x, y| x * y } # => 6
```

#### 「Proc」対「lambda」

一般的には、lambdaの方がメソッドに似ているので、Procよりも直感的であると言われ、
return を呼ぶと単に終了してくれ、項数に厳しいという理由から、
Proc の機能が必要でない限り、lambdaが選ばれる。

lambda で作った Proc は、以下の点で他の Proc とは異なる。

##### 1. return キーワードの意味

lambdaの場合は、 return は単に戻るだけ。

```rb
def double(callable_object)
  callable_object.call * 2
end

1 = lambda { return 10 }
double(1) # => 20
```

Proc の場合は、 Procが定義されたスコープから戻る。

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

##### 2. 引数のチェック方法

引数の数について、Proc は多い部分を切り落とし、足りない引数には nil を割り当ててくれるが、
違った項数で lambda を呼び出すと、 ArgumentError になる。

#### Methodオブジェクト

Object#method を呼び出すと、メソッドそのものを Method オブジェクトとして取得できる。
Method オブジェクトは、あとで Method#call を使って実行できる。

Ruby 2.1 には、Kernel#singelton_method があり、特異メソッドの名前から Method オブジェクトに変換することもできる。

Method オブジェクトはブロックや lambda に似ているが、
lambda は定義されたスコープで評価される（クロージャ）一方、
Method は所属するオブジェクトのスコープで評価される。


#### UnboundMethod

UnboundMethod は、元のクラスやモジュールから引き離されたメソッドのようなもの。

https://docs.ruby-lang.org/ja/latest/class/UnboundMethod.html

> レシーバを持たないメソッドを表すクラスです。呼び出すためにはレシーバにバインドする必要があります。

> Module#instance_method や Method#unbind により生成し、後で UnboundMethod#bind によりレシーバを割り当てた Method オブジェクトを作ることができます。

```rb
module MyModule
  def my_method
    42
  end
end

unbound = MyModule.instance_method(:my_method)
unbound.class # => UnboundMethod
```

UnboundMethod を呼び出すことはできないが、そこから通常のメソッドを生成することは可能。
UnboundMethod#bind を使って、 UnboundMethod をオブジェクトに束縛する。

ただし、 UnboundMethod は元のクラスと同じクラス（またはサブクラス）のオブジェクトにしか束縛できないため、以下の例のように、Module#define_method に渡すことで束縛する。

```rb
String.send :define_method, :another_method, unbound

"abc".another_method # => 42
```

String の define_method は private メソッドのため、動的メソッドを使って呼び出す。

#### Active Supportの例

ActiveSupport には「自動読み込み」システムがあり、定数を使った時に、それが定義されたファイルを自動的に読み込むクラスやモジュールがある。
例えば、標準の Kernle#load メソッドを再定義する Lodabale というモジュールが含まれている。

クラスが Lodable をインクルードした時に、 Lodable#load が Kernel#load よりも継承チェーンの下にあれば、 load の呼び出しは Lodable#load にたどり着く。
インクルードした Lodable を削除、つまり通常の Kernel#load を使いたくなった場合、下記のようなコードによってそれを行う。

Lodable.exclude_from(MyClass) を呼び出すと、上記のコードが instance_method を呼び出して、元の Kernel#load を UnboundMethod として取得する。
そして、（コンテキスト探査機を使って）MyClass にその新しい load メソッドを定義する。
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

UnboundMethod によって、Kernel#load と MyClass#load はよく似ているが、Kernel#load と Lodable#load は全く呼び出されない。

#### まとめ

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
ß
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
  * isntance_eval 、 instance_exec 、 class_exec
* クリーンルームとは、ブロックを評価するためだけに生成されたオブジェクトのこと。
  * 例: obj = Object.new
* ブロックとオブジェクト（Proc）は、＆修飾 によって相互に変換できる。
* メソッドとオブジェクト（Method や UnboundMethod）はModule#instance_method や Method#unbind 、 UnboundMethod#bind によって相互に変換することができる。
* 呼び出し可能オブジェクト（ブロック、Proc 、lambda）は、return キーワードの意味や引数のチェック方法について動作が異なり、評価されるスコープにおいて通常のメソッドと異なる。
