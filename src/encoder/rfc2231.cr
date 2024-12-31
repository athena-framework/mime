require "uri"

struct Athena::MIME::Encoder::RFC2231
  def_clone

  def encode(input : String, charset : String? = "UTF-8", first_line_offset : Int32 = 0, max_line_length : Int32? = nil) : String
    max_line_length = 75 if 0 >= max_line_length

    String.build input.size do |io|
      line_length = 0

      0.step(to: input.size, by: 4, exclusive: true) do |offset|
        sub_string = input[offset, 4]

        if line_length + sub_string.bytesize > max_line_length
          io << '\r'
          io << '\n'
          line_length = 0
        end

        URI.encode_path_segment io, sub_string
        line_length += sub_string.bytesize
      end
    end
  end
end
