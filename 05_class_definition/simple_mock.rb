# 次の仕様を満たすモジュール SimpleMock を作成してください
#
# SimpleMockは、次の2つの方法でモックオブジェクトを作成できます
# 特に、2の方法では、他のオブジェクトにモック機能を付与します
# この時、もとのオブジェクトの能力が失われてはいけません
# また、これの方法で作成したオブジェクトを、以後モック化されたオブジェクトと呼びます
# 1.
# ```
# SimpleMock.new
# ```
#
# 2.
# ```
# obj = SomeClass.new
# SimpleMock.mock(obj)
# ```
#
# モック化したオブジェクトは、expectsメソッドに応答します
# expectsメソッドには2つの引数があり、それぞれ応答を期待するメソッド名と、そのメソッドを呼び出したときの戻り値です
# ```
# obj = SimpleMock.new
# obj.expects(:imitated_method, true)
# obj.imitated_method #=> true
# ```
# モック化したオブジェクトは、expectsの第一引数に渡した名前のメソッド呼び出しに反応するようになります
# そして、第2引数に渡したオブジェクトを返します
#
# モック化したオブジェクトは、watchメソッドとcalled_timesメソッドに応答します
# これらのメソッドは、それぞれ1つの引数を受け取ります
# watchメソッドに渡した名前のメソッドが呼び出されるたび、モック化したオブジェクトは内部でその回数を数えます
# そしてその回数は、called_timesメソッドに同じ名前の引数が渡された時、その時点での回数を参照することができます
# ```
# obj = SimpleMock.new
# obj.expects(:imitated_method, true)
# obj.watch(:imitated_method)
# obj.imitated_method #=> true
# obj.imitated_method #=> true
# obj.called_times(:imitated_method) #=> 2
# ```
# https://github.com/willnet/reading-metaprogramming-ruby/blob/try/05_class_definition/simple_mock.rb
module SimpleMock
  class << self
    def mock(obj)
      obj.extend(SimpleMock)
    end

    def new
      mock(Object.new)
    end
  end

  def expects(method_name, value)
    define_singleton_method(method_name) do
      @counter[method_name] += 1 if @counter&.key?(method_name)
      value
    end
    @expects ||= []
    @expects.push(method_name.to_sym)
  end

  def watch(method_name)
    (@counter ||= {})[method_name] = 0

    return if @expects&.include?(method_name.to_sym)
    define_singleton_method(method_name) do
      @counter[method_name] += 1 if @counter&.key?(method_name)
    end
  end

  def called_times(method_name)
    @counter[method_name]
  end
end