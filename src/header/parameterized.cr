require "./unstructured"

class Athena::MIME::Header::Parameterized < Athena::MIME::Header::Unstructured
  property parameters = Hash(String, String?).new

  def initialize(
    name : String,
    value : String,
    parameters : Hash(String, String?)
  )
    super name, value

    parameters.each do |k, v|
      self.[k] = v
    end
  end

  def [](name : String) : String
    @parameters[name]? || ""
  end

  def []=(key : String, value : String?) : Nil
    @parameters = @parameters.merge({key => value})
  end

  def body_to_s(io : IO) : Nil
    super

    @parameters.each do |k, v|
      next unless v

      io << ';' << ' ' << k << ' ' << v
    end
  end
end
