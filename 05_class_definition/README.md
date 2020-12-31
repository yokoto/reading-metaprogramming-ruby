# Class Definition

## Overview of 5 - 5.2.1

### クラス定義の中身

クラス定義にはメソッド定義だけではなく、あらゆるコードを置くことができる。
クラス（やモジュール）定義の中では、クラスがカレントオブジェクト self になる。
クラスとモジュールは単なるオブジェクトなため、クラスも self になれる。

```rb
class MyClass
  puts 'Hello'
end

result = class MyClass
  self
end

result # => MyClass
```

### カレントクラス

* カレントクラス（カレントモジュール）
  * Ruby のインタプリタは、常にカレントクラス（あるいはカレントモジュール）の参照を追跡している。
  * def で定義された全てのメソッドは、カレントクラスのインスタンスメソッドになる。
    * トップレベルのカレントクラスは、 main のクラスである Object 。
      * トップレベルにメソッドを定義すると、Object のインスタンスメソッドになる。
  * class （module）キーワードでクラスをオープンすると、そのクラスがカレントクラスになる。
  * カレントクラスを参照するキーワードはない。
    * カレントオブジェクトは self で参照を獲得できる。
    * クラス定義の中では、カレントオブジェクト self とカレントクラス（定義しているクラス）は同じ。
    * メソッドの中では、カレントオブジェクトのクラスがカレントクラスになる。
  * クラスへの参照を持っていれば、クラスは class_eval（あるいは module_eval）でオープンできる。

### class_eval

* Module#class_eval （module_eval）
  * そこにあるクラスのコンテキストでブロックを評価する。
  * self とカレントクラスを変更する。
    * BasicObject#instance_eval は self を変更するだけ（厳密にはカレントクラスをレシーバの特異クラスに変更している）。
  * クラスを参照している変数なら何でも使える。
    * class キーワードは定数を必要とする。
  * フラットスコープを持っているため、class_eval ブロックのスコープの外側にある変数も参照できる。
    * class キーワードは現在の束縛を捨てて、新しいスコープをオープンする。
  * 外部のパラメータをブロックに渡せる module_exec や class_exec というメソッドがある。
  * クラス定義をオープンして、def を使ってメソッドを定義したい場合に使う。
    * クラス以外のオブジェクトをオープンしたい場合は instance_eval を使えば良い。

```rb
def add_method_to(a_class)
  a_class.class_eval do
    def m; 'Hello!'; end
  end
end

add_method_to String
"abc".m # => "Hello!"
```

### クラスインスタンス変数

* クラスのインスタンス変数とクラスのオブジェクトのインスタンス変数は別物。
* クラスインスタンス変数にアクセスできるのはクラスだけ。
  * クラスのインスタンスやサブクラスからはアクセスできない。

```rb
class MyClass
  @my_var = 1
  def self.read; @my_var; end
  def write; @my_var = 2; end
  def read; @my_var; end
end

obj = MyClass.new
obj.read # => nil
obj.write
obj.read # => 2
MyClass.read # => 1
```

### クラス変数

* クラスインスタンス変数とは違い、サブクラスやインスタンスメソッドからもアクセスできる。

```rb
class C
  @@v = 1
end

class D < C
  def my_method; @@v; end
end

D.new.my_method # => 1
```

* クラス変数はクラスではなく、クラス階層に属している。
  * Ruby2.0 からはトップレベルでクラス変数にアクセスすると警告が表示される。

下記の例では、@@v は main のコンテキストで定義されているので、  
main のクラスである Object とその子孫に属している。  
MyClass クラスは Object を継承しているので、同じクラス変数を共有していることになる。  

```rb
@@v = 1

class MyClass
  @@v = 2
end

@@v # => 2
```

### クイズ：クラスのタブー

* Class.new
  * クラスは Class クラスのインスタンスなので、Class.new を呼び出して作ることができる。
  * Class.new は引数（新しいクラスのスーパークラス）と、新しいクラスのコンテキストで評価するブロックを受け取る。

下記の例のように書き換えが可能。

```rb
class MyClass < Array
  def my_method
    'Hello!'
  end
end
```

```rb
c = Class.new(Array) do
  def my_method
    'Hello!'
  end
end
MyClass = c
```

## Overview of 5.3 - 5.


### 特異メソッド

* 単一のオブジェクトに特化したメソッドのこと

```rb
str = "just a regular string"

def str.title?
  self.upcase == self
end

str.title? # => false
str.methods.grep(/title?/) # => [:title?]
str.singleton_methods # => [:title?]
```

### ダックタイピング

* ダックタイピング
  * Ruby などの動的言語では、オブジェクトの「型」はそのクラスとは厳密にはむす結び付いていない。
    * 「型」はオブジェクトが反応するメソッドの集合にすぎない。
    * あるオブジェクトがそのクラスのインスタンスかどうかを気にする必要がない。
  * 静的言語では、あるオブジェクトが T の型を持つのは、それが T クラスに属している（あるいは T インターフェースを実装している）からだと考える。  

### クラスメソッドの真実

* クラスメソッドはクラスの特異メソッド。
  * 定数で参照したオブジェクト（=クラス）のメソッドを呼び出している。

下記の例における object の部分には、オブジェクトの参照、クラス名の定数、self のいずれかが使える。

```rb
def object.method
  # メソッドの中身
end
```

```rb
def obj.a_singleton_method; end
def MyClass.another_class_method; end
```

### クラスマクロ

* クラス定義の中で使える単なるクラスメソッド。
* Module#attr_accessorは Module クラスで定義されている。
  * self がモジュールであってもクラスであっても使える。

```rb
class MyClass
  attr_accessor :my_attribute
end
```

### deprecate の例

下記の例では、古いメソッドへの呼び出しを動的メソッドで捕捉し、警告を出しつつ呼び出しを新しいメソッドに転送している。

```rb
class Book
  def title # ...

  def subtitle # ...

  def lend_to(user)
    puts "Lending to #{user}"
    # ...
  end

  def self.deprecate(old_method, new_method)
    define_method(old_method) do |*args, &block|
      warn "Warning: #{old_method}() is deprecated. Use #{new_method}()."
      send(new_method, *args, &block)
    end
  end

  deprecate :GetTitle, :title
  deprecate :LEND_TO_USER, :lend_to
  deprecate :title2, :subtitle
```

### 特異クラス

* 特異クラス（メタクラス、シングルトンクラス）
  * オブジェクトの特異メソッドが住んでいる場所。
  * Object#singleton_class か class << という構文を使わなければ見ることができない。
  * インスタンスをひとつしか持てない。
  * 継承ができない。

```rb
class << an_object
  # your code is here...
end
```

#### 特異クラスの参照を取得する

1. 特異クラスを参照する self を戻す。
2. Object#singleton_class というメソッドを使う。

```rb
[1] pry(main)> obj = Object.new
=> #<Object:0x00007ff154a90978>
[2] pry(main)> singleton_class = class << obj 
[2] pry(main)*   self
[2] pry(main)* end  
=> #<Class:#<Object:0x00007ff154a90978>>
[3] pry(main)> singleton_class
=> #<Class:#<Object:0x00007ff154a90978>>
[4] pry(main)> singleton_class.class
=> Class
[5] pry(main)> obj.singleton_class
=> #<Class:#<Object:0x00007ff154a90978>>
[6] pry(main)> obj.singleton_class.class
=> Class
```

#### 特異クラスとメソッド探索

オブジェクトが特異メソッドを持っていれば、  
Rubyは通常のクラスではなく、**特異クラスのメソッドから探索を始める**。
特異クラスにメソッドがなければ、  
継承チェーンを上へ進み、特異クラスのスーパークラスである通常のクラスにたどり着く。
そこから先はいつも通りになる。

```rb
class C
  def a_method
    'C#a_method()'
  end
end

class D < C; end
obj = D.new
obj.a_method # => "C#a_method()"

class << obj
  def a_singleton_method
    'obj#a_singleton_method()'
  end
end
obj.singleton_class # => #<Class:#<D:0x00007fbd491bb558>>（#obj）
obj.singleton_class.super_class # => D
# obj ->(class) #obj ->(superclass) D ->(superclass) C ->(superclass) Object
```

#### 特異クラスと継承

Rubyには、クラス、特異クラス、スーパークラスを構成するパターンがある。　　
下記のように配置されていることで、サブクラスからクラスメソッドを呼び出すことができる。

* 「**特異クラスのスーパークラスがスーパークラスの特異クラス**」
  * #D のスーパークラスは #C で、#C は C の特異クラス。
    * #D のメソッド探索がスーパークラス #C に上って、そこでメソッドを見つける。
  * 同じように、#C のスーパークラスは #Object。

```rb
class C
  class << self
    def a_class_method
      'C.a_class_method()'
    end
  end
end

D.a_class_method # => "C.a_class_method()"
```

#### 特異クラスと instance_eval

instance_eval は self を変更し、 class_eval は self とカレントクラスの両方を変更すると学んだが、  
instance_eval もカレントクラスを変更する。
instance_eval はカレントクラスをレシーバの特異クラスに変更する。

下記の例では、instance_eval で特異メソッドを定義している。
とはいえカレントクラスを変更するために instance_eval を使うことはほとんどないため、  
instance_eval の意味は「self を変更したい」のままで構わない。

```rb
s1, s2 = "abc", "def"

s1.instance_eval do
  def swoosh!; reverse; end
end

s1.swoosh! # => "cba"
s2.respond_to?(:swoosh!) # => false
```

#### クラスのアトリビュート

クラスのアトリビュートを定義したいときは、  
Class クラスをオープンして、そこにアトリビュートを定義した場合、すべてのクラスにアトリビュートが追加されてしまう。  
アトリビュートはペアのメソッドであり、特異クラスにメソッドを定義すると、それはクラスメソッドになるため、  
特異クラスにアトリビュートを定義すれば良い。

```rb
class MyClass
  class << self
    attr_accessor :c
  end
end

MyClass.c = 'It works!'
MyClass.c # => "It works!"
```

### 大統一理論

* Rubyのオブジェクトモデルの7つのルール

1. オブジェクトは1種類しかない。それが通常のオブジェクトかモジュールになる。
2. モジュールは1種類しかない。それが通常のモジュール、クラス、特異クラスのいずれかになる。
3. メソッドは1種類しかない。メソッドはモジュール（大半はクラス）に住んでいる。
4. すべてのオブジェクトは（クラスも含めて）「本物のクラス」を持っている。それが通常のクラスか特異クラスである。
5. すべてのクラスは（BasicObject 除いて）ひとつの祖先（スーパークラスかモジュール）を持っている。つまり、あらゆるクラスが BasicObject に向かって1本の継承チェーンを持っている。
6. オブジェクトの特異クラスのスーパークラスは、オブジェクトのクラスである。クラスの特異クラスのスーパークラスはクラスのスーパークラスの特異クラスである。
7. メソッドを呼び出すときは、Rubyはレシーバの本物のクラスに向かって「右へ」進み、継承チェーンを「上へ」進む。

### クイズ：モジュールの不具合

モジュールをインクルードしてクラスメソッドを定義する方法を考える。

クラスがモジュールをインクルードすると、モジュールのインスタンスメソッドが手に入るが、  
クラスメソッドは、モジュールの特異クラスの中にいるため手に入らない。

```rb
module MyModule
  def self.my_method; 'hello'; end
end

class MyClass
  include MyModule
end

MyClass.my_method # NoMethodError!
```

モジュールをインクルードしてクラスメソッドを定義するには、MyClass の特異クラスで、モジュールをインクルードする。  

これを**クラス拡張**と呼ぶ。


```rb
module MyModule
  def my_method; 'hello'; end
end

class MyClass
  class << self
    include MyModule
  end
end

MyClass.my_method # => "hello"
```

