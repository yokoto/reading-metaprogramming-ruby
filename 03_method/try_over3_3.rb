TryOver3 = Module.new
# Q1
# 以下要件を満たすクラス TryOver3::A1 を作成してください。
# - run_test というインスタンスメソッドを持ち、それはnilを返す
# - `test_` から始まるインスタンスメソッドが実行された場合、このクラスは `run_test` メソッドを実行する
# - `test_` メソッドがこのクラスに実装されていなくても `test_` から始まるメッセージに応答することができる
# - TryOver3::A1 には `test_` から始まるインスタンスメソッドが定義されていない

# p.58とp.73参考
class TryOver3::A1
  def run_test
    nil
  end

  # https://docs.ruby-lang.org/ja/latest/method/BasicObject/i/method_missing.html
  # BasicObject#method_missing
  # method_missing(name, *args) -> object
  # method_missing を override する場合は
  # 対象のメソッド名に対して Object#respond_to? が真を返すようにしてください。
  # そのためには、Object#respond_to_missing? も同様に override する必要があります。
  def method_missing(name, *args)
    # https://github.com/meganemura/reading-metaprogramming-ruby/blob/6070de3ca9857a7ad346064d1ff29baec4842eaf/03_method/try_over3_3.rb#L14-L18
    # https://github.com/willnet/reading-metaprogramming-ruby/blob/893eebca3ce7a1ed20c8597716716f24a04e7f74/03_method/try_over3_3.rb#L13-L19
    return run_test if start_with_test_?(name)

    super
  end

  def respond_to_missing?(name)
    start_with_test_?(name) || super
  end

  private

  def start_with_test_?(name)
    name.to_s.start_with?('test_')
  end
end

# Q2
# 以下要件を満たす TryOver3::A2Proxy クラスを作成してください。
# - TryOver3::A2Proxy は initialize に TryOver3::A2 のインスタンスを受け取り、それを @source に代入する
# - TryOver3::A2Proxy は、@sourceに定義されているメソッドが自分自身に定義されているように振る舞う
# https://github.com/meganemura/reading-metaprogramming-ruby/blob/6070de3ca9857a7ad346064d1ff29baec4842eaf/03_method/try_over3_3.rb#L26-L53
class TryOver3::A2
  def initialize(name, value)
    instance_variable_set("@#{name}", value)
    self.class.attr_accessor name.to_sym unless respond_to? name.to_sym
  end
end

class TryOver3::A2Proxy
  def initialize(instance)
    @source = instance
  end

  private

  attr_reader :source

  def method_missing(name, *args)
    if source.respond_to?(name)
      # https://nyakanishi.work/%E3%80%90ruby%E3%80%91public_send%E3%81%A8send%E3%81%AB%E3%81%A4%E3%81%84%E3%81%A6/
      # “public_sendとsendの違い 端的に言うとpublicメソッドを呼べるかprivateメソッドも呼べるかの違いです。 ”
      return source.public_send(name, *args)
    end

    super
  end

  # p.65 respond_to?によって呼び出される。
  # ゴーストメソッドがあればtrueを戻し、
  # なければsuperを呼び出し、常にfalseを戻す
  def respond_to_missing?(method, include_private = false)
    source.respond_to?(method) || super
  end
end


# Q3
# 前回 OriginalAccessor の my_attr_accessor で定義した getter/setter に boolean の値が入っている場合には #{name}? が定義されるようなモジュールを実装しました。
# 今回は、そのモジュールに boolean 以外が入っている場合には hoge? メソッドが存在しないようにする変更を加えてください。
# （以下は god の模範解答を一部変更したものです。以下のコードに変更を加えてください）
# https://github.com/meganemura/reading-metaprogramming-ruby/blob/6070de3ca9857a7ad346064d1ff29baec4842eaf/03_method/try_over3_3.rb#L59-L86
module TryOver3::OriginalAccessor2
  def self.included(mod)
    # test_try_over3_3 の orignal_accessor_included_instance メソッドを参照。
    # Class オブジェクト（クリーンルームのクラス定義）に対して特異メソッドを定義している。
    # TryOver3::OriginalAccessor2 インクルードしたクラスにだけ
    # my_attr_accessor が定義される。
    mod.define_singleton_method :my_attr_accessor do |attr_sym|
      # self == mod
      # つまり、include したクラスのインスタンスメソッドを定義している。
      define_method attr_sym do
        @attr
      end

      define_method "#{attr_sym}=" do |value|
        @attr = value

        if [true, false].include?(value) && !respond_to?("#{attr_sym}?")
          # なんで self.class ？
          # Class オブジェクトではなく、Class クラスのインスタンスメソッドを定義している。
          self.class.define_method "#{attr_sym}?" do
            @attr == true
          end
        elsif respond_to?("#{attr_sym}?")
          # このモジュールのインスタンスメソッド name を未定義にします。
          # undef_method(*name) -> self
          # スーパークラスに同名のメソッドがあっても
          # その呼び出しはエラーになる
          self.class.undef_method("#{attr_sym}?")
        end
      end
    end
  end
end


# Q4
# 以下のように実行できる TryOver3::A4 クラスを作成してください。
# TryOver3::A4.runners = [:Hoge]
# TryOver3::A4::Hoge.run
# # => "run Hoge"
# https://github.com/meganemura/reading-metaprogramming-ruby/blob/6070de3ca9857a7ad346064d1ff29baec4842eaf/03_method/try_over3_3.rb#L94-L114
# https://github.com/toshimaru/reading-metaprogramming-ruby/blob/8f6a46c761b0125ec1c4243a865455a47d3ba92f/03_method/try_over3_3.rb#L77-L95
class TryOver3::A4
  class << self
    attr_accessor :runners

    # p.66 存在しない定数を参照すると、Rubyは定数の名前を  const_missing にシンボルとして渡す。
    # クラス名は単なる定数なので、ここではHogeという不明な参照が Module#const_missing に渡される。
    def const_missing(const_name)
      return super unless self.runners.include?(const_name)

      # そして、runners が定数への参照を持っていれば、
      # run という名前の特異メソッドを、
      # （変数 const_name を共有する必要があるため、）
      # フラットスコープを使ったクラス定義の中で定義する。
      Class.new do
        define_singleton_method(:run) { "run #{const_name}" }
      end

      # const_set(name, value) -> object
      # モジュールに name で指定された名前の定数を value という値として定義し、value を返します。
      # const_set(const_name, klass)
    end
  end
end

# Q5. チャレンジ問題！ 挑戦する方はテストの skip を外して挑戦してみてください。
#
# TryOver3::TaskHelper という include すると task というクラスマクロが与えられる以下のようなモジュールがあります。
module TryOver3::TaskHelper
  def self.included(klass)
    klass.define_singleton_method :task do |name, &task_block|
      # ↓からのスコープでは self == klass となる。
      # つまり、include したクラスの特異メソッドを定義している。
      define_singleton_method(name) do
        puts "start #{Time.now}"
        block_return = task_block.call
        puts "finish #{Time.now}"
        block_return
      end

      # https://docs.ruby-lang.org/ja/latest/method/Module/i/const_missing.html
      # Module#const_missing
      # const_missing(name)
      # 定義されていない定数を参照したときに Ruby インタプリタがこのメソッドを呼びます。
      define_singleton_method(:const_missing) do |const_name|
        # クラスマクロ task の引数をスネークケースからキャメルケースに変換
        new_klass_name = name.to_s.split("_").map{ |w| w[0] = w[0].upcase; w }.join
        # 参照された定数がクラスマクロ task を使って定義されたものでなければ
        # NameError となるため super としている。
        return super(const_name) if const_name.to_s != new_klass_name
        
        Class.new do
          define_singleton_method(:run) do
            warn "Warning: #{klass}::#{new_klass_name}.run is deprecated"
            klass.public_send(name)
          end
        end
      end
    end
  end
end

# TryOver3::TaskHelper は include することで以下のような使い方ができます
class TryOver3::A5Task
  include TryOver3::TaskHelper

  task :foo do
    "foo"
  end
end
# irb(main):001:0> A3Task::Foo.run
# start 2020-01-07 18:03:10 +0900
# finish 2020-01-07 18:03:10 +0900
# => "foo"

# 今回 TryOver3::TaskHelper では TryOver3::A5Task::Foo のように Foo クラスを作らず TryOver3::A5Task.foo のようにクラスメソッドとして task で定義された名前のクラスメソッドでブロックを実行するように変更したいです。
# 現在 TryOver3::TaskHelper のユーザには TryOver3::A5Task::Foo.run のように生成されたクラスを使って実行しているユーザが存在します。
# 今回変更を加えても、その人たちにはこれまで通り生成されたクラスのrunメソッドでタスクを実行できるようにしておいて、warning だけだしておくようにしたいです。
# TryOver3::TaskHelper を修正してそれを実現してください。 なお、その際、クラスは実行されない限り生成されないものとします。
#
# 変更後想定する使い方
# メソッドを使ったケース
# irb(main):001:0> TryOver3::A5Task.foo
# start 2020-01-07 18:03:10 +0900
# finish 2020-01-07 18:03:10 +0900
# => "foo"
#
# クラスのrunメソッドを使ったケース
# irb(main):001:0> TryOver3::A5Task::Foo.run
# Warning: TryOver3::A5Task::Foo.run is deprecated
# start 2020-01-07 18:03:10 +0900
# finish 2020-01-07 18:03:10 +0900
# => "foo"
