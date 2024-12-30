module Athena::MIME::Encoder::Interface
  abstract def encode(input : IO, charset : String? = "UTF-8", first_line_offset : Int32 = 0, max_line_length : Int32 = 0) : String
end
