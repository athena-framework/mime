class Athena::MIME::Header::Unstructured < Athena::MIME::Header::Abstract(String)
  @value : String

  def initialize(name : String, @value : String)
    super name
  end

  def_equals @value, @name, @max_line_length, @lang, @charset

  def body : String
    @value
  end

  def body=(body : String)
    @value = body
  end

  def body_to_s(io : IO) : Nil
    io << self.encode_words self, @value
  end
end
