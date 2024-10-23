# Convenience alias to make referencing `Athena::MIME` types easier.
alias AMIME = Athena::MIME

module Athena::MIME
  VERSION = "0.1.0"

  struct Address
    private FROM_STRING_PATTERN = /(?<displayName>[^<]*)<(?<addrSpec>.*)>[^>]*/

    getter address : String
    getter name : String

    def self.new(addresses : Enumerable(self | String)) : Array(self)
      addresses.map do |a|
        new a
      end.to_a
    end

    def self.new(address : self | String) : self
      return address if address.is_a? self

      return new(address) unless address.includes? '<'

      # Validate
      raise "BUG: Invalid address"
    end

    def initialize(address : String, name : String = "")
      @address = address.strip
      @name = name.gsub(/\n|\r/, "").strip

      # TODO: Validate the email?
    end

    def_clone

    def to_s(io : IO) : Nil
      @address.to_s io
    end

    def encoded_address : String
      @address
      # self.class.encoder.encode @address
    end
  end

  module Encoder
    module Interface
      abstract def encode(string : String, charset : String? = "UTF-8", first_line_offset : Int32 = 0, max_line_length : Int32 = 0) : String
    end

    struct QuotedPrintable
      include Athena::MIME::Encoder::Interface

      def encode(string : String, charset : String? = "UTF-8", first_line_offset : Int32 = 0, max_line_length : Int32 = 0) : String
        self.standardize string
      end

      private def standardize(string : String) : String
        # Transform CR or LF or CRLF
        string = string.gsub /0D(?!=0A)|(?<!=0D)=0A/, "=0D=0A"

        # Transform =0D=0A to CRLF
        string = string
          .gsub("\t=0D=0A", "=09\r\n")
          .gsub(" =0D=0A", "=20\r\n")
          .gsub("=0D=0A", "\r\n")

        string
      end
    end
  end

  module Header
    module Interface
      abstract def name : String

      def body; end

      def body=(body); end

      abstract def max_line_length : Int32
      abstract def max_line_length=(max_line_length : Int32)

      # Render this header as a compliant string.
      abstract def to_s(io : IO) : Nil

      # Returns the header's body, prepared for folding into a final header value.
      #
      # This is not necessarily RFC 2822 compliant since folding white space is not added at this stage (see `#to_s` for that).
      def body_to_s : String
        String.build do |io|
          self.body_to_s io
        end
      end

      protected abstract def body_to_s(io : IO) : Nil
    end

    abstract class Abstract(T)
      include Interface

      getter name : String
      property max_line_length : Int32 = 76
      property lang : String? = nil
      property charset : String = "UTF-8"

      def initialize(@name : String); end

      abstract def body : T
      abstract def body=(body : T)

      def_clone

      def to_s(io : IO) : Nil
        # TODO: Is there a way to make this more stream based?
        io << self.tokens_to_string self.to_tokens
      end

      private def generate_token_lines(token : String) : Array(String)
        token.split /(\r\n)/
      end

      private def tokens_to_string(tokens : Array(String)) : String
        line_count = 0
        header_lines = ["#{@name}: "]

        current_line = header_lines[line_count]

        tokens.each_with_index do |token, i|
          if (token == "\r\n") || (i > 0 && (current_line + token).size > @max_line_length) && current_line != ""
            header_lines << ""
            header_lines[line_count] = current_line
            line_count += 1
            current_line = header_lines[line_count]
          end

          unless token == "\r\n"
            header_lines[line_count] += token
          end
        end

        header_lines.join("\r\n")
      end

      private def to_tokens(string : String? = nil) : Array(String)
        string = string || self.body_to_s

        tokens = [] of String
        string.split /(?=[ \t])/ do |token|
          tokens.concat self.generate_token_lines token
        end

        tokens
      end

      private def token_needs_encoding?(token : String) : Bool
        token.matches? /[\x00-\x08\x10-\x19\x7F-\xFF\r\n]/
      end

      private def encodable_word_tokens(string : String) : Array(String)
        tokens = [] of String
        encoded_token = ""

        string.split /(?=[\t ])/ do |token|
          if self.token_needs_encoding? token
            encoded_token += token
          else
            unless encoded_token.empty?
              tokens << encoded_token
              encoded_token = ""
            end
            tokens << token
          end
        end

        unless encoded_token.empty?
          tokens << encoded_token
        end

        tokens
      end

      private def encode_words(header : AMIME::Header::Interface, input : String, used_lenth : Int32 = -1) : String
        String.build do |io|
          tokens = self.encodable_word_tokens input

          tokens.each do |token|
            # See RFC 2822, Sect 2.2 (really 2.2 ??)
            if self.token_needs_encoding? token
            else
              io << token
            end
          end
        end
      end

      private def create_phrase(io : IO, header : AMIME::Header::Interface, input : String, charset : String, shorten : Bool = false) : Nil
        input.to_s io
      end
    end

    class Unstructured < Abstract(String)
      @value : String

      def initialize(name : String, @value : String)
        super name
      end

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

    class Date < Abstract(Time)
      @value : Time

      def initialize(name : String, @value : Time)
        super name
      end

      def body : Time
        @value
      end

      def body=(body : Time)
        @value = body
      end

      def body_to_s(io : IO) : Nil
        @value.to_rfc2822 io
      end
    end

    class Path < Abstract(AMIME::Address)
      @value : AMIME::Address

      def initialize(name : String, @value : AMIME::Address)
        super name
      end

      def body : AMIME::Address
        @value
      end

      def body=(body : AMIME::Address)
        @value = body
      end

      def body_to_s(io : IO) : Nil
        io << '<'
        @value.to_s io
        io << '>'
      end
    end

    class Mailbox < Abstract(AMIME::Address)
      @value : AMIME::Address

      def initialize(name : String, @value : AMIME::Address)
        super name
      end

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

    class MailboxList < Abstract(Array(AMIME::Address))
      @value : Array(AMIME::Address)

      def initialize(name : String, @value : Array(AMIME::Address))
        super name
      end

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

    class Parameterized < Unstructured
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

    class Collection
      private UNIQUE_HEADERS = ["date"]

      # :nodoc:
      enum Type
        TEXT
        DATE
      end

      @headers = Hash(String, Array(AMIME::Header::Interface)).new { |hash, key| hash[key] = Array(AMIME::Header::Interface).new }
      @line_length = 76

      def self.new(*headers : AMIME::Header::Interface)
        new headers
      end

      def initialize(headers : Enumerable(AMIME::Header::Interface) = [] of AMIME::Header::Interface)
        headers.each do |h|
          self << h
        end
      end

      def_clone

      def to_s(io : IO) : Nil
        @headers.each do |name, collection|
          collection.each do |header|
            header.to_s(io)
            io << '\r' << '\n'
          end
        end
      end

      def []?(name : String, _type : T.class) : T? forall T
        return unless header = self.[name]?

        header.as T
      end

      def []?(name : String) : AMIME::Header::Interface?
        name = name.downcase

        return unless headers = @headers[name]?

        headers.first?
      end

      def <<(header : AMIME::Header::Interface) : self
        # Check header class
        header.max_line_length = @line_length
        name = header.name.downcase

        # Check for unique headers

        @headers[name] << header

        self
      end

      def header_body(name : String)
        return unless header = self.[name]?

        header.body
      end

      def has_key?(name : String) : Bool
        @headers.has_key? name.downcase
      end

      def add_text_header(name : String, body : String) : Nil
        self << AMIME::Header::Unstructured.new name, body
      end

      def add_date_header(name : String, body : Time) : Nil
        self << AMIME::Header::Date.new name, body
      end

      def add_path_header(name : String, body : AMIME::Address | String) : Nil
        self << AMIME::Header::Path.new name, AMIME::Address.new(body)
      end

      def add_mailbox_header(name : String, body : AMIME::Address | String) : Nil
        self << AMIME::Header::Mailbox.new name, AMIME::Address.new(body)
      end

      def add_mailbox_list_header(name : String, body : Array(AMIME::Address | String)) : Nil
        self << AMIME::Header::MailboxList.new name, AMIME::Address.new(body)
      end

      def add_parameterized_header(name : String, body : String, params : Hash(String, String) = {} of String => String) : Nil
        self << AMIME::Header::Parameterized.new name, body, params
      end

      protected def header_parameter(name : String, parameter : String, value : String?) : Nil
        unless header = self.[name]?
          raise "BUG: Missing header"
        end

        unless header.is_a? Parameterized
          raise "BUG: Not parameterizable"
        end

        header[parameter] = value
      end

      protected def upsert(name : String, body : T, adder : Proc(String, T, Nil)) : Nil forall T
        if header = self[name]?
          return header.body = body
        end

        adder.call name, body
      end
    end
  end

  module Part
    abstract struct Abstract
      getter headers : AMIME::Header::Collection = AMIME::Header::Collection.new

      abstract def body_to_s(io : IO) : Nil
      # abstract def body_to_iterable : Iterator

      abstract def media_type : String
      abstract def media_sub_type : String

      def prepared_headers : AMIME::Header::Collection
        headers = @headers.clone

        headers.upsert "content-type", "#{self.media_type}/#{self.media_sub_type}", ->headers.add_parameterized_header(String, String)

        headers
      end

      def to_s(io : IO) : Nil
        self.prepared_headers.to_s io
        io << "\r\n"
        self.body_to_s io
      end
    end

    abstract struct AbstractText < Abstract
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
        io << self.encoder.encode self.body, @charset
      end

      def body : String
        @body.gets_to_end
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

    struct Text < AbstractText
    end

    struct Data < AbstractText
    end
  end

  class Message
    getter headers : AMIME::Header::Collection
    getter body : AMIME::Part::Abstract?

    def initialize(
      headers : AMIME::Header::Collection? = nil,
      @body : AMIME::Part::Abstract? = nil
    )
      # TODO: Need to clone this?
      @headers = headers || AMIME::Header::Collection.new
    end
  end

  class Email < Message
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

      header.add_addresses AMIME::Address.new addresses

      self
    end

    private def set_list_address_header_body(name : String, addresses : Enumerable(AMIME::Address | String)) : self
      addresses = AMIME::Address.new addresses

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

    private def ensure_body_is_valid
      if @text.nil? && @html.nil? && @attachments.empty?
        raise "BUG: A message must have a text or an HTML part or attachments."
      end
    end
  end
end

email = AMIME::Email
  .new
  .subject("Hello World")
  .date(Time.utc)
  .subject("Goodbye World")
  .date(Time.local)
  .return_path("foo@example.com")
  .to("foo@example.com")
  .from("bar@example.com")
  .priority(:low)
  .text("Hello there good sir!")

puts email.body.to_s
