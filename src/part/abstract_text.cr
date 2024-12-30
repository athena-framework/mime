abstract struct Athena::MIME::Part::AbstractText < Athena::MIME::Part::Abstract
  private DEFAULT_ENCODERS = ["quoted-printable", "base64"]

  @@encoders = Hash(String, AMIME::Encoder::Interface).new

  property disposition : String? = nil
  property name : String? = nil

  @encoding : String

  def initialize(
    @body : IO,
    @charset : String? = "UTF-8",
    @subtype : String = "plain",
    encoding : String? = nil
  )
    if body.is_a? ::File
      if !::File::Info.readable?(body.path) || ::File.directory?(body.path)
        raise "BUG: File is not readable"
      end
    end

    # Seekable?

    if encoding
      raise "BUG: Unexpected encoding type" unless DEFAULT_ENCODERS.includes? encoding

      @encoding = encoding
    else
      @encoding = choose_encoding
    end
  end

  # :inherit:
  def media_type : String
    "text"
  end

  # :inherit:
  def media_sub_type : String
    @subtype
  end

  # :inherit:
  def body_to_s(io : IO) : Nil
    io << self.encoder.encode @body, @charset
  end

  def prepared_headers : AMIME::Header::Collection
    headers = super

    headers.upsert "content-type", "#{self.media_type}/#{self.media_sub_type}", ->headers.add_parameterized_header(String, String)

    if charset = @charset
      headers.header_parameter "content-type", "charset", charset
    end

    if (name = @name.presence) && ("form-data" != @disposition)
      headers.header_parameter "content-type", "name", name
    end

    headers.upsert "content-transfer-encoding", @encoding, ->headers.add_text_header(String, String)

    if !headers.has_key?("content-disposition") && (disposition = @disposition)
      headers.upsert "content-disposition", disposition, ->headers.add_parameterized_header(String, String)

      if name = @name
        headers.header_parameter "content-disposition", "name", name
      end
    end

    headers
  end

  private def choose_encoding : String
    @charset.nil? ? "base64" : "quoted-printable"
  end

  private def encoder : AMIME::Encoder::Interface
    case @encoding
    when "quoted-printable" then @@encoders[@encoding] = AMIME::Encoder::QuotedPrintable.new
    else
      @@encoders[@encoding]
    end
  end
end
