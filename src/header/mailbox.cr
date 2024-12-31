class Athena::MIME::Header::Mailbox < Athena::MIME::Header::Abstract(Athena::MIME::Address)
  @value : AMIME::Address

  def initialize(name : String, @value : AMIME::Address)
    super name
  end

  def_equals @value, @name, @max_line_length, @lang, @charset

  def body : AMIME::Address
    @value
  end

  def body=(body : AMIME::Address)
    @value = body
  end

  def body_to_s(io : IO) : Nil
    str = @value.encoded_address

    if name = @value.name
      str = "#{self.create_phrase(io, self, name, @charset, true)} <#{str}>"
    end

    str
  end
end
