struct Athena::MIME::Encoder::QuotedPrintable
  include Athena::MIME::Encoder::Interface

  def encode(input : IO, charset : String? = "UTF-8", first_line_offset : Int32 = 0, max_line_length : Int32 = 0) : String
    self.standardize self.encode_internal input.gets_to_end
  end

  private MAX_LINE_LENGTH = 75

  private def encode_internal(input : String) : String
    String.build input.size do |io|
      line_length = 0

      input.each_char do |char|
        if char.ord < 32 || char.ord > 126 || char.in?('=', '?', '_', '\r', '\n')
          line_length = self.encode io, char, line_length
        else
          line_length = self.soft_wrap io, line_length
          io << char
        end
      end
    end
  end

  private def encode(io : IO, char : Char, line_length : Int32) : Int32
    # Ensure each char is fully written on its own line.
    line_length = self.soft_wrap io, line_length, char.bytes.size * 3

    char.each_byte do |byte|
      io << '='
      byte.to_s io, base: 16, upcase: true, precision: 2
    end

    line_length
  end

  private def soft_wrap(io, line_length : Int32, increment : Int32 = 1) : Int32
    new_line_length = line_length + increment

    return new_line_length if new_line_length <= MAX_LINE_LENGTH

    io << '='
    io << '\r'
    io << '\n'

    0
  end

  private def standardize(string : String) : String
    # Transform CR or LF to CRLF
    string = string.gsub /0D(?!=0A)|(?<!=0D)=0A/, "=0D=0A"

    # Transform =0D=0A to CRLF
    string = string
      .gsub("\t=0D=0A", "=09\r\n")
      .gsub(" =0D=0A", "=20\r\n")
      .gsub("=0D=0A", "\r\n")

    case last_char = string[-1].ord
    when 0x09 then string.sub(-1, "=09")
    when 0x20 then string.sub(-1, "=20")
    else
      string
    end
  end
end
