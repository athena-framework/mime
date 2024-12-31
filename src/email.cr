class Athena::MIME::Email < Athena::MIME::Message
  enum Priority
    HIGHEST
    HIGH
    NORMAL
    LOW
    LOWEST

    def to_s
      "#{self.value} (#{super.titleize})"
    end
  end

  @text : IO? = nil
  getter text_charset : String? = nil

  @html : IO? = nil
  getter html_charset : String? = nil

  @attachments = Array(AMIME::Part::Data).new

  # Used to avoid wrong body hash in DKIM signatures with multiple parts (e.g. HTML + TEXT) due to multiple boundaries.
  @cached_body : AMIME::Part::Abstract? = nil

  def subject : String?
    if header = @headers["subject"]?
      return header.body
    end
  end

  def subject(subject : String) : self
    @headers.upsert "subject", subject, ->@headers.add_text_header(String, String)

    self
  end

  def date : Time?
    if header = @headers["date"]?
      return header.body
    end
  end

  def date(date : Time) : self
    @headers.upsert "date", date, ->@headers.add_date_header(String, Time)

    self
  end

  def return_path : AMIME::Address?
    if header = @headers["return-path"]?
      return header.body
    end
  end

  def return_path(address : AMIME::Address | String) : self
    @headers.upsert "return-path", AMIME::Address.new(address), ->@headers.add_path_header(String, AMIME::Address)

    self
  end

  def sender : AMIME::Address?
    if header = @headers["sender"]?
      return header.body
    end
  end

  def sender(address : AMIME::Address | String) : self
    @headers.upsert "sender", AMIME::Address.new(address), ->@headers.add_mailbox_header(String, AMIME::Address)

    self
  end

  def from : Array(AMIME::Address)
    if header = @headers["from"]?
      return header.body
    end

    [] of AMIME::Address
  end

  def from(*addresses : AMIME::Address | String) : self
    self.set_list_address_header_body "from", addresses
  end

  def add_from(*addresses : AMIME::Address | String) : self
    self.add_list_address_header_body "from", addresses
  end

  def reply_to : Array(AMIME::Address)
    if header = @headers["reply-to"]?
      return header.body
    end

    [] of AMIME::Address
  end

  def reply_to(*addresses : AMIME::Address | String) : self
    self.set_list_address_header_body "reply-to", addresses
  end

  def add_reply_to(*addresses : AMIME::Address | String) : self
    self.add_list_address_header_body "reply-to", addresses
  end

  def to : Array(AMIME::Address)
    if header = @headers["to"]?
      return header.body
    end

    [] of AMIME::Address
  end

  def to(*addresses : AMIME::Address | String) : self
    self.set_list_address_header_body "to", addresses
  end

  def add_to(*addresses : AMIME::Address | String) : self
    self.add_list_address_header_body "to", addresses
  end

  def cc : Array(AMIME::Address)
    if header = @headers["cc"]?
      return header.body
    end

    [] of AMIME::Address
  end

  def cc(*addresses : AMIME::Address | String) : self
    self.set_list_address_header_body "cc", addresses
  end

  def add_cc(*addresses : AMIME::Address | String) : self
    self.add_list_address_header_body "cc", addresses
  end

  def bcc : Array(AMIME::Address)
    if header = @headers["bcc"]?
      return header.body
    end

    [] of AMIME::Address
  end

  def bcc(*addresses : AMIME::Address | String) : self
    self.set_list_address_header_body "bcc", addresses
  end

  def add_bcc(*addresses : AMIME::Address | String) : self
    self.add_list_address_header_body "bcc", addresses
  end

  private def add_list_address_header_body(name : String, addresses : Enumerable(AMIME::Address | String)) : self
    unless header = @headers[name, AMIME::Header::MailboxList]?
      return self.set_list_address_header_body name, addresses
    end

    header.add_addresses AMIME::Address.create addresses

    self
  end

  private def set_list_address_header_body(name : String, addresses : Enumerable(AMIME::Address | String)) : self
    addresses = AMIME::Address.create addresses

    if header = @headers[name]?
      header.body = addresses
    else
      @headers.add_mailbox_list_header name, addresses
    end

    self
  end

  def priority : AMIME::Email::Priority
    priority = (@headers.header_body("x-priority") || "").as String

    if !(val = priority.to_i?(strict: false)) || !(member = Priority.from_value? val)
      return Priority::NORMAL
    end

    member
  end

  def priority(priority : AMIME::Email::Priority) : self
    @headers.add_text_header "x-priority", priority.to_s

    self
  end

  def text(body : String | IO | Nil, charset : String = "UTF-8") : self
    @cached_body = nil
    @text = body.is_a?(String) ? IO::Memory.new(body) : body
    @text_charset = charset

    self
  end

  def text_body : IO
    @text
  end

  def html(body : String | IO | Nil, charset : String = "UTF-8") : self
    @cached_body = nil
    @html = body.is_a?(String) ? IO::Memory.new(body) : body
    @html_charset = charset

    self
  end

  def html_body : IO
    @html
  end

  def body : AMIME::Part::Abstract
    if body = super
      return body
    end

    self.generate_body
  end

  private def generate_body : AMIME::Part::Abstract
    if cached_body = @cached_body
      return cached_body
    end

    self.ensure_body_is_valid

    html_part, other_parts, related_parts = self.prepare_parts

    part = (text = @text) ? AMIME::Part::Text.new(text, @text_charset) : nil

    if html_part
      part = html_part
    end

    unless related_parts.empty?
      # TODO: Handle this
    end

    unless other_parts.empty?
      # TODO: Handle this
    end

    @cached_body = part.not_nil!
  end

  private def prepare_parts : {AMIME::Part::Text?, Array(AMIME::Part::Abstract), Array(AMIME::Part::Abstract)}
    names = [] of String
    html_part = nil
    if html = @html

      # TODO: Handle HTML
    end

    other_parts = Array(AMIME::Part::Abstract).new
    related_parts = Array(AMIME::Part::Abstract).new

    # TODO: Handle attachments

    if html_part
      html_part = AMIME::Part::Text.new html.not_nil!, @html_charset.not_nil!, "html"
    end

    {html_part, other_parts, related_parts}
  end

  private def ensure_validity : Nil
    self.ensure_body_is_valid

    if "1" == @headers.header_body("x-unsent")
      raise AMIME::Exception::Logic.new "Cannot send messages marked as 'draft'."
    end

    super
  end

  private def ensure_body_is_valid : Nil
    if @text.nil? && @html.nil? && @attachments.empty?
      raise AMIME::Exception::Logic.new "A message must have a text or an HTML part or attachments."
    end
  end
end
