require "./interface"

abstract class Athena::MIME::Header::Abstract(T)
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

  private def encode_words(header : AMIME::Header::Interface, input : String, used_length : Int32 = -1) : String
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
