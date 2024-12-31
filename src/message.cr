class Athena::MIME::Message
  property headers : AMIME::Header::Collection
  property body : AMIME::Part::Abstract?

  def initialize(
    headers : AMIME::Header::Collection? = nil,
    @body : AMIME::Part::Abstract? = nil
  )
    # TODO: Need to clone this?
    @headers = headers || AMIME::Header::Collection.new
  end

  def prepared_headers
  end

  def to_s(io : IO) : Nil
  end

  private def ensure_validity : Nil
    if !@headers.header_body("to") && !@headers.header_body("cc") && !@headers.header_body("bcc")
      raise AMIME::Exception::Logic.new "An email must have a 'to', 'cc', or 'bcc' header."
    end

    if !@headers.header_body("from") && !@headers.header_body("sender")
      raise AMIME::Exception::Logic.new "An email must have a 'from' or a 'sender' header."
    end

    super
  end
end
