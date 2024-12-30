require "./address"
require "./message"
require "./email"

require "./encoder/*"
require "./header/*"
require "./part/*"

# Convenience alias to make referencing `Athena::MIME` types easier.
alias AMIME = Athena::MIME

module Athena::MIME
  VERSION = "0.1.0"

  module Encoder; end

  module Header; end

  module Part; end
end

# email = AMIME::Email
#   .new
#   .subject("Hello World")
#   .date(Time.utc)
#   .subject("Goodbye World")
#   .date(Time.local)
#   .return_path("foo@example.com")
#   .to("foo@example.com")
#   .from("bar@example.com")
#   .priority(:low)
#   .text("Hello there good sir!")

# p email
