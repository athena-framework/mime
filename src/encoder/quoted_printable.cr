struct Athena::MIME::Encoder::QuotedPrintable
  include Athena::MIME::Encoder::Interface

  def encode(input : IO, charset : String? = "UTF-8", first_line_offset : Int32 = 0, max_line_length : Int32? = nil) : String
    self.standardize self.quoted_printable_encode(input.gets_to_end)
  end

  def quoted_printable_encode(str)
    max_line_length = 75
    hex = "0123456789ABCDEF"
    line_pos = 0

    String.build do |result|
      i = 0

      while i < str.bytesize
        c = str.bytes[i]
        # p(len: str.bytesize - 1 - i, byte: c)

        if c == 0x0D && i + 1 < str.bytesize && str.bytes[i + 1] == 0x0A
          result << "\r\n"
          i += 2
          line_pos = 0
        else
          if c.chr.control? || c == 0x7F || c >= 0x80 || c == 0x3D || (c == 0x20 && i + 1 < str.bytesize && str.bytes[i + 1] == 0x0D)
            needs_line_break = false

            line_pos += 3
            if c <= 0x7F && (line_pos) > max_line_length
              needs_line_break = true
            elsif c > 0x7F && c <= 0xDF && ((line_pos + 3) > max_line_length)
              needs_line_break = true
            elsif c > 0xDF && c <= 0xEF && ((line_pos + 6) > max_line_length)
              needs_line_break = true
            elsif c > 0xEF && c <= 0xF4 && ((line_pos + 9) > max_line_length)
              needs_line_break = true
            end

            if needs_line_break
              result << "=\r\n"
              line_pos = 3
            end

            result << "="
            result << hex[c >> 4]
            result << hex[c & 0xF]
          else
            line_pos += 1
            if line_pos > max_line_length
              result << "=\r\n"
              line_pos = 1
            end
            result << c.chr
            # line_pos += 1
          end
          i += 1
        end
      end
    end
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
