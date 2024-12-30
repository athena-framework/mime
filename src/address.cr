struct Athena::MIME::Address
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
