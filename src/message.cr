class Athena::MIME::Message
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
