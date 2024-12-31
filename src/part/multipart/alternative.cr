struct Athena::MIME::Part::Multipart::Alternative < Athena::MIME::Part::Abstract
  include Athena::MIME::Part::AbstractMultipart

  # :inherit:
  def media_sub_type : String
    "alternative"
  end
end
