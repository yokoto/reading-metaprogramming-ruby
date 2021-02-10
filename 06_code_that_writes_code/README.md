# Code that writes code

## Overview of 6.1

### CheckedAttributes モジュールと attr_checked メソッド

#### 上司の依頼

上司の依頼で、 attr_checked というクラスマクロを CheckedAttributes モジュールをインクルードしたときにだけ、アクセスできるようにする。  

attr_checked はアトリビュートの名前とブロックを受け取り、ブロックは妥当性確認のために使う。
代入したアトリビュートの値に対して、ブロックが true を返さなければ実行時エラーとする。

```rb
class Person
  include CheckedAttributes

  attr_checked :age do |v|
    v >= 18
  end
end

me = Person.new
me.age = 39 # OK
me.age = 12 # 例外！
```

#### 開発計画

1. eval を使った add_checked_attribute という名前のカーネルメソッドを書いて、クラスに超シンプルな妥当性確認済みのアトリビュートを追加できるようにする。
2. add_checked_attribute をリファクタリングして、 eval を削除する。
3. ブロックでアトリビュートの妥当性を確認する。
4. add_checked_attribute をすべてのクラスで利用可能な attr_checked という名前のクラスマクロに変更する。
5. フックを使って任意のクラスに attr_checked を追加するモジュールを書く。

## Overview of 6.2

### Kernel#eval

* Kernel#eval は instance_eval や class_eval と同じ eval 族。
  * ブロックの代わりにRubyのコード文字列を受け取る。
  * 渡されたコード文字列を実行して、その結果を戻す。

```rb
array = [10, 20]
element = 30
eval("array << element") # => [10, 20, 30]
```

### REST Client の例

* REST Client は、シンプルなHTTPクライアントライブラリ。
* 通常のRubyコマンドを get などのHTTPメソッドと一緒に発行できるインタプリタが内蔵されている。  

コード文字列を作成及び評価することで、ループの中で一気に4つのメソッドすべてを定義している。

```rb
POSSIBLE_VERBS = ['get', 'put', 'post', 'delete']

POSSIBLE_VERBS.each do |m|
  eval <<-end_eval
    def #{m}(path, *args, &b)
      r[path].#{m}(*args, &b)
    end
  end_eval
end
```

#### ヒアドキュメント

* 通常のRubyの文字列。
* クオートの代わりに、 <<- と任意の終端子（ここでは end_eval）で文字列が開始する。
* その終端子のみが含まれる行で文字列が終了する。

### Binding オブジェクトの例

* Binding はスコープをオブジェクトにまとめたもの。
* Kernel#binding メソッドで Binding オブジェクトを作ってローカルスコープを取得すれば、そのスコープを持ち回すことができる。
* Binding オブジェクトにはスコープは含まれているがコードは含まれていない。
  * ブロックよりもより「純粋」なクロージャと考えることができる。
* 取得したスコープでコードを評価するには、 eval の引数に Binding を渡す。

```rb
class MyClass
  def my_method
    @x = 1
    binding
  end
end

b = MyClass.new.my_method

eval "@x", b # => 1
```

* Ruby にはトップレベルのスコープの Binding である TOPEVEL_BINDING 定数が用意されている。

```rb
class AnotherClass
  def my_method
    eval "self", TOPLEVEL_BINDING
  end
end

AnotherClass.new.my_method # => main
```

* 現在の binding の pry を呼び出す行をコードに追加すると、デバッガのように使うことができる。
  * Object#pry メソッドはオブジェクトのスコープでインタラクティブセッションを開く。

```rb
require "pry"; binding.pry
```

### irb の例

* irb は、標準入力やファイルをパースして、それぞれの行を eval に渡すシンプルなプログラム。
  * こうしたプログラムをコードプロセッサと呼ぶ。

下記の例では、statements に Ruby のコード行、@binding に irb がコードを実行するコンテキストである binding 、file と line は例外が発生したときにスタックとレースを調整するために使われる。

eval の最初の引数である Binding は、特定のオブジェクトで irb セッションをネストして開くようなときに使われる。
既存の irb セッションのなかで、irb とオブジェクトの名前を入力すれば、以降のコマンドはそのオブジェクトのコンテキストで評価される。これは instance_eval とよく似ている。

```rb
eval(statements, @binding, file, line)
```

```rb
# このファイルは2行目で例外が発生する
x = 1 / 0
```

```
=> ZeroDivisionError: divided by 0
    from exception.rb:2:in `/'
```

### 「コード文字列」対「ブロック」

eval は常に文字列を必要とするが、
instance_eval と class_eval はコード文字列またはブロックのいずれかを受け取ることができる。

```rb
array = ['a', 'b', 'c']
x = 'd'
array.instance_eval "self[1] = x"

array # => ["a", "d", "c"]
```

### eval の問題点

* コード文字列は、シンタックスハイライトや自動補完といったエディタの機能が使えない。
* Ruby は評価するまでコード文字列の構文エラーを報告しない。
  * 実行時に予期せずに失敗するような脆弱性のあるプログラムになる可能性もある。

### コードインジェクション

* 配列探索
  * eval を使ったユーティリティを書いて、サンプルの配列にメソッドを呼び出すことで、メソッドを確認することができる。

```rb
def explore_array(method)
  code = "['a', 'b', 'c'].#{method}"
  puts "Evaluating: #{code}"
  eval code
end

loop { p explore_array(gets.chomp) }
```

```
<= find_index("b")
=> Evaluating: ['a', 'b', 'c'].find_index("b")
  1
<= map! {|e| e.next }
=> Evaluating: ['a', 'b', 'c'].map! {|e| e.next }
  ["b", "c", "d"]
```

* ディレクトリのファイルを一覧にするコマンドが渡されると、悪意のあるユーザーが任意のコードを実行できてしまう。

```rb
<= object_id; Dir.glob("*")
=> ['a', 'b', 'c'].object_id; Dir.glob("*") # => [プライベートな情報がズラズラと表示される]
```

### コードインジェクションから身を守る

先に見た「REST Clientの例」や「コードインジェクション」の例は、動的メソッドと動的ディスパッチで置き換えることができる。

```rb
POSSIBLE_VERBS.each do |m|
  define_method m do |path, *args, &b|
    r[path].send(m, *args, &b)
  end
end
```

```rb
def explore_array(method, *arguments)
  ['a', 'b', 'c'].send(method, *arguments)
end
```

コードインジェクションの例では、ウェブのユーザーがブロックをメソッドに渡せなくなっている。

### オブジェクトの汚染とセーフレベル

* Rubyは、潜在的に安全ではないオブジェクト（特に外部から来たオブジェクト）に自動的に汚染の印をつけてくれる。

```rb
# ユーザー入力を読み込む
user_input = "User input: #{gets()}"
puts user_input.tainted?

# <= x = 1
# => true
```

* セーフレベル
  * グローバル変数 $SAFE に値を設定する。
  * デフォルトの0から3の4つから選択できる。
  * 0より大きいセーフレベルでは、Rubyは汚染した文字列を評価できない。

```rb
$SAFE = 1
user_input = "User input: #{gets()}"
eval user_input

# <= x = 1
# => SecutiryError: Insecure operation - eval
```

### ERBの例

- Rubyのデフォルトのテンプレートシステムで、コードプロセッサであり、Rubyをどのようなファイルにも埋め込むことができる。

```erb
<p><strong>Wake up!</strong>It's a nice sunny <%= Time.new.strftime("%A") %>.</p>
```

```rb
require 'erb'
erb = ERB.new(File.read('template.rhtml'))
erb.run

# => <p><strong>Wake up!</strong>It's a nice sunny Friday.</p>
```

下記の例では、new_toplevel は、 TOPLEVEL_BINDING のコピーを戻すメソッドで、 @src は、ERB タグの中身、 @safe_level はユーザーが必要とするセーフレベルである。

セーフレベルが設定されていなければ、タグの中身がそのまま評価され、設定されていれば、ERBはサンドボックス(erb用に制御した環境)を作る。

そのなかで、グローバルのセーフレベルをユーザーの指定と一致させ、Proc をクリーンルームにして、別のスコープでコードを実行している。

```rb
class ERB
  def result(b=new_toplevel)
    if @safe_level
      proc {
        $SAFE = @safe_level
        eval(@src, b, (@filename || '(erb)'), 0)
      }.call
    else
      eval(@src, b, (@filename || '(erb)'), 0)
    end
  end
  # ...
end
```

### Kernel#eval と Kernel#load

* ファイル名を受け取り、そのファイルのコードを実行するメソッド。
  * load と require は eval に似ている。
    * ファイルの中身は自分で制御できるため、load や require には eval を使う時ほどのセキュリティの懸念はない。
    * ただし、セーフレベル1以上ではファイルのインポートに制限がかかり、セーフレベル2以上では汚染したファイル名を load に使うことはできない。

## Overview of 6.3 - 6.9

### クイズ：アトリビュートのチェック（手順１）

### クイズ：アトリビュートのチェック（手順2）

### クイズ：アトリビュートのチェック（手順3）

### クイズ：アトリビュートのチェック（手順4）

### フックメソッド

### クイズ：アトリビュートのチェック（手順5）

### まとめ
