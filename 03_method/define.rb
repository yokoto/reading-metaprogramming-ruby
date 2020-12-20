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
      method_name = "hoge_#{arg}"
      # コンストラクタの中で動的にメソッドを定義するので、
      # 特異メソッドを定義する必要がある。
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
    base.extend ClassMethods
  end

  module ClassMethods
    def my_attr_accessor(attribute)
      define_method attribute do
        instance_variable_get "@#{attribute}"
      end
      define_method "#{attribute}=" do |value|
        # boolean値を代入した際のみ動的にメソッドが定義される、
        # つまりクラスメソッドの中で動的にメソッドが定義されるため、
        # define_singleton_methodを使う必要がある。
        # https://github.com/meganemura/reading-metaprogramming-ruby/blob/6070de3ca9857a7ad346064d1ff29baec4842eaf/03_method/define.rb#L50-L54
        if [true, false].include?(value)
          define_singleton_method("#{attribute}?") do
            !!send(attribute)
          end
        end
        instance_variable_set("@#{attribute}", value)
      end
      # # https://chaika.hatenablog.com/entry/2016/10/19/153728
      # define_method "#{attribute}?" do |bool|
      #   !!bool === bool
      # end
    end
  end
end
