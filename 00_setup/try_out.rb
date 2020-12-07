class TryOut
  # このクラスの仕様
  # コンストラクタは、2つまたは3つの引数を受け付ける。引数はそれぞれ、ファーストネーム、ミドルネーム、ラストネームの順で、ミドルネームは省略が可能。
  # full_nameメソッドを持つ。これは、ファーストネーム、ミドルネーム、ラストネームを半角スペース1つで結合した文字列を返す。ただし、ミドルネームが省略されている場合に、ファーストネームとラストネームの間には1つのスペースしか置かない
  # first_name=メソッドを持つ。これは、引数の内容でファーストネームを書き換える。
  # upcase_full_nameメソッドを持つ。これは、full_nameメソッドの結果をすべて大文字で返す。このメソッドは副作用を持たない。
  # upcase_full_name! メソッドを持つ。これは、upcase_full_nameの副作用を持つバージョンで、ファーストネーム、ミドルネーム、ラストネームをすべて大文字に変え、オブジェクトはその状態を記憶する
  
  def initialize(first_name, last_name, middle_name = nil)
    @first_name = first_name
    @last_name = last_name
    @middle_name = middle_name
  end

  def full_name
    (middle_name? ? names_with_middle_name : names_without_middle_name).join(' ')
  end

  def first_name=(new_first_name)
    @first_name = new_first_name
  end

  def upcase_full_name
    upcase_name(full_name)
  end

  def upcase_full_name!
    if middle_name?
      @first_name, @last_name, @middle_name = names_with_middle_name.map { |name| upcase_name(name) }
    else
      @first_name, @last_name = names_without_middle_name.map { |name| upcase_name(name) }
    end
    full_name
  end

  private

  def middle_name?
    !@middle_name.nil?
  end

  def names_with_middle_name
    [@first_name, @last_name, @middle_name]
  end

  def names_without_middle_name
    [@first_name, @last_name]
  end

  def upcase_name(name)
    name.chars.map(&:upcase).join
  end
end
