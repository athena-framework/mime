require "./text"

class Athena::MIME::Part::Data < Athena::MIME::Part::Text
  def self.from_path(path : String | Path, name : String? = nil, content_type : String? = nil) : self
    new
  end

  @filename : String?
  @media_type : String
  @content_id : String?

  def initialize(
    body : String | IO | AMIME::Part::File,
    filename : String? = nil,
    content_type : String? = nil,
    encoding : String? = nil
  )
    if body.is_a?(AMIME::Part::File) && filename.nil?
      filename = body.path
    end

    content_type ||= body.is_a?(AMIME::Part::File) ? body.content_type : "application/octet-stream"

    @media_type, sub_type = content_type.split '/'

    super body, sub_type: sub_type, encoding: encoding

    if filename
      @filename = filename
      @name = filename
    end

    self.disposition = "attachment"
  end

  def as_inline : self
    self.disposition = "inline"

    self
  end

  def content_id=(id : String) : self
    if !id.includes? '@'
      raise AMIME::Exception::InvalidArgument.new "The '#{id}' CID is invalid as it does not contain an '@' symbol."
    end

    @content_id = id

    self
  end

  def content_id : String
    @content_id ||= self.generate_content_id
  end

  def has_content_id? : Bool
    !@content_id.nil?
  end

  private def generate_content_id : String
    "#{Random::Secure.hex(16)}@athena"
  end
end
