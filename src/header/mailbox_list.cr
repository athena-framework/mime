class Athena::MIME::Header::MailboxList < Athena::MIME::Header::Abstract(Array(Athena::MIME::Address))
  @value : Array(AMIME::Address)

  def initialize(name : String, @value : Array(AMIME::Address))
    super name
  end

  def_equals @value, @name, @max_line_length, @lang, @charset

  def body : Array(AMIME::Address)
    @value
  end

  def body=(body : Array(AMIME::Address))
    @value = body
  end

  def add_addresses(addresses : Array(AMIME::Address)) : Nil
    @value.concat addresses
  end

  def body_to_s(io : IO) : Nil
  end
end
