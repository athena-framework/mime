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
  end

  module Header
    module Interface
      abstract def name : String

      def body; end

      def body=(body); end

      abstract def max_line_length : Int32
      abstract def max_line_length=(max_line_length : Int32)
    end

    abstract class Abstract(T)
      include Interface

      getter name : String
      property max_line_length : Int32 = 76

      def initialize(@name : String); end

      abstract def body : T
      abstract def body=(body : T)
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

      private def check_header(name : String, body, & : ->) : Nil
        if header = self[name]?
          return header.body = body
        end

        yield
      end
    end
  end

  module Part
    abstract class Abstract
    end

    class Text < Abstract
    end

    class Data < Text
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

    def subject(value : String) : self
      @headers.add_text_header "subject", value

      self
    end

    def date : Time?
      if header = @headers["date"]?
        return header.body
      end
    end

    def date(date : Time) : self
      @headers.add_date_header "date", date

      self
    end

    def return_path : AMIME::Address?
      if header = @headers["return-path"]?
        return header.body
      end
    end

    def return_path(address : AMIME::Address | String) : self
      @headers.add_path_header "return-path", AMIME::Address.new(address)

      self
    end

    def sender : AMIME::Address?
      if header = @headers["sender"]?
        return header.body
      end
    end

    def sender(address : AMIME::Address | String) : self
      @headers.add_mailbox_header "sender", AMIME::Address.new(address)

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
  .return_path("foo@example.com")
  .sender("foo@example.com")
  .from("bar@example.com")
  .priority(:low)
  .text("Hello there good sir!")

pp email.body
