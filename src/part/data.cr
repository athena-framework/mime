struct Athena::MIME::Part::Data < Athena::MIME::Part::AbstractText
  def self.from_path(path : String | Path, name : String? = nil, content_type : String? = nil) : self
    new
  end

  @filename : String?
  @media_type : String

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
      self.name = filename
    end

    self.disposition = "attachment"
  end

  def as_inline : self
    self.disposition = "inline"

    self
  end
end
