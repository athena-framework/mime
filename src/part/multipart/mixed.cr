struct Athena::MIME::Part::Multipart::Mixed < Athena::MIME::Part::Abstract
  include Athena::MIME::Part::AbstractMultipart

  # :inherit:
  def media_sub_type : String
    "mixed"
  end
end
