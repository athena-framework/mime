require "./address"
require "./message"
require "./email"

require "./header/*"
require "./part/*"

# Convenience alias to make referencing `Athena::MIME` types easier.
alias AMIME = Athena::MIME

module Athena::MIME
  VERSION = "0.1.0"

  module Encoder
    module Interface
      abstract def encode(input : IO, charset : String? = "UTF-8", first_line_offset : Int32 = 0, max_line_length : Int32 = 0) : String
    end

    struct QuotedPrintable
      include Athena::MIME::Encoder::Interface

      def encode(input : IO, charset : String? = "UTF-8", first_line_offset : Int32 = 0, max_line_length : Int32 = 0) : String
        self.standardize self.internal_encode input
      end

      private def standardize(string : String) : String
        # Transform CR or LF to CRLF
        string = string.gsub /0D(?!=0A)|(?<!=0D)=0A/, "=0D=0A"

        # Transform =0D=0A to CRLF
        string = string
          .gsub("\t=0D=0A", "=09\r\n")
          .gsub(" =0D=0A", "=20\r\n")
          .gsub("=0D=0A", "\r\n")

        string
      end

      # Based on https://github.com/php/php-src/blob/55e8ebe29b92a5e586119b3774ed0a050de5ecbe/ext/standard/quot_print.c#L140
      private MAX_LINE_LEGTH = 76
      private HEX            = "0123456789ABCDEF"

      # TODO: Make this more idomatic Crystal
      private def internal_encode(string : String) : String
        lp = 0

        String.build do |io|
          string.each_byte.with_index do |byte, idx|
            if (byte == 0x0D && string[idx + 1] == 0x0A && idx + 1 < string.size)
              io << "\r\n"
              idx += 1
              lp = 0
            else
              if byte < 32 || byte == 0x7f || byte & 0x80 != 0 || byte == 0x3D || (byte == 0x20 && string[idx + 1]? == 0x0D)
                if ((lp += 3) > MAX_LINE_LEGTH) ||
                   ((byte > 0x7f && byte <= 0xdf) && ((lp + 3) > MAX_LINE_LEGTH)) ||
                   ((byte > 0xdf && byte <= 0xef) && ((lp + 6) > MAX_LINE_LEGTH)) ||
                   ((byte > 0xef && byte <= 0xf4) && ((lp + 9) > MAX_LINE_LEGTH))
                  io << '=' << "\r\n"
                  lp = 3
                end
                io << '=' << HEX[byte >> 4] << HEX[byte & 0x0F]
              else
                if (lp += 1) > MAX_LINE_LEGTH
                  io << '=' << "\r\n"
                  lp = 1
                end
                io << byte.chr
              end
            end
          end
        end
      end
    end
  end

  module Header; end

  module Part; end
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

pp email.body
