# Q1.
# 次の動作をする A1 class を実装する
# - "//" を返す "//"メソッドが存在すること
class A1
  define_method '//' do
    "//"
  end
end

# Q2.
# 次の動作をする A2 class を実装する
# - 1. "SmartHR Dev Team"と返すdev_teamメソッドが存在すること
# - 2. initializeに渡した配列に含まれる値に対して、"hoge_" をprefixを付与したメソッドが存在すること
# - 2で定義するメソッドは下記とする
#   - 受け取った引数の回数分、メソッド名を繰り返した文字列を返すこと
#   - 引数がnilの場合は、dev_teamメソッドを呼ぶこと
# - また、2で定義するメソッドは以下を満たすものとする
#   - メソッドが定義されるのは同時に生成されるオブジェクトのみで、別のA2インスタンスには（同じ値を含む配列を生成時に渡さない限り）定義されない
class A2
  def initialize(array)
    array.each do |arg|
      # 2. initializeに渡した配列に含まれる値に対して、"hoge_" をprefixを付与したメソッドが存在すること
      method_name = "hoge_#{arg}"
      # p.119
      # initializeで生成されるインスタンス(単一のオブジェクト)に対してメソッドを定義するので、
      # 特異メソッドを定義する必要がある。
      # この時selfは #<A:0x00005597a9a98490>
      # https://github.com/meganemura/reading-metaprogramming-ruby/blob/6070de3ca9857a7ad346064d1ff29baec4842eaf/03_method/define.rb#L19-L26
      # define_singleton_method(symbol) { ... } -> Symbol
      # self に特異メソッド name を定義します。
      # https://docs.ruby-lang.org/ja/latest/method/Object/i/define_singleton_method.html
      self.define_singleton_method(method_name) do |n|
        return dev_team if n.nil?

        method_name * n
      end
    end
  end

  # 1. "SmartHR Dev Team"と返すdev_teamメソッドが存在すること
  def dev_team
    'SmartHR Dev Team'
  end
end

# Q3.
# 次の動作をする OriginalAccessor モジュール を実装する
# - OriginalAccessorモジュールはincludeされたときのみ、my_attr_accessorメソッドを定義すること
# - my_attr_accessorはgetter/setterに加えて、boolean値を代入した際のみ真偽値判定を行うaccessorと同名の?メソッドができること

# NOTE: 分からなすぎたがp.169でそれっぽいコードを見つけた。
module OriginalAccessor
  def self.included(base)
    # extend(*modules) -> self
    # 引数で指定したモジュールのインスタンスメソッドを self の特異メソッドとして追加します。
    # Module#include は、クラス(のインスタンス)に機能を追加しますが、
    # extend は、ある特定のオブジェクトだけにモジュールの機能を追加したいときに使用します。
    # extend の機能は、「特異クラスに対する Module#include」と言い替えることもできます。
    # https://docs.ruby-lang.org/ja/latest/method/Object/i/extend.html
    base.extend ClassMethods
  end

  module ClassMethods
    def my_attr_accessor(attribute)
      define_method attribute do
        instance_variable_get "@#{attribute}"
      end
      # ブロックを与えた場合、
      # 定義したメソッドの実行時にブロックがレシーバクラスのインスタンスの上で
      # BasicObject#instance_eval される。
      # https://docs.ruby-lang.org/ja/latest/method/Module/i/define_method.html
      # つまり、ブロック内部の define_singleton_method のレシーバは
      # define_method の self であり、
      # OriginalAccessor を include した特定のオブジェクト。
      define_method "#{attribute}=" do |value|
        # p.119 特異メソッドの導入
        # my_attr_accessorのsetterのレシーパとなる、
        # 単一のオブジェクトに特化したメソッドを定義する必要があるため、
        # 特異メソッドを定義するために
        # Object#define_singleton_methodを使う必要がある。
        # https://github.com/meganemura/reading-metaprogramming-ruby/blob/6070de3ca9857a7ad346064d1ff29baec4842eaf/03_method/define.rb#L50-L54
        if [true, false].include?(value)
          define_singleton_method("#{attribute}?") do
            !!send(attribute)
          end
        end
        instance_variable_set("@#{attribute}", value)
      end
    end
  end
end
