struct EmailTest < ASPEC::TestCase
  def test_subject : Nil
    e = AMIME::Email.new
    e.subject "Subject"
    e.subject.should eq "Subject"
  end

  def test_date : Nil
    e = AMIME::Email.new
    e.date now = Time.utc
    e.date.should eq now
  end

  def test_return_path : Nil
    e = AMIME::Email.new
    e.return_path "foo@example.com"
    e.return_path.should eq AMIME::Address.new("foo@example.com")
  end

  def test_sender : Nil
    e = AMIME::Email.new
    e.sender "foo@example.com"
    e.sender.should eq AMIME::Address.new "foo@example.com"

    e.sender s = AMIME::Address.new("bar@example.com")
    e.sender.should eq s
  end

  def test_from : Nil
    e = AMIME::Email.new
    helene = AMIME::Address.new "helene@example.com"
    thomas = AMIME::Address.new "thomas@example.com"
    caramel = AMIME::Address.new "caramel@example.com"

    e.from "fred@example.com", helene, thomas

    v = e.from
    v.size.should eq 3
    v[0].should eq AMIME::Address.new "fred@example.com"
    v[1].should eq helene
    v[2].should eq thomas

    e.add_from "lucas@example.com", caramel

    v = e.from
    v.size.should eq 5
    v[0].should eq AMIME::Address.new "fred@example.com"
    v[1].should eq helene
    v[2].should eq thomas
    v[3].should eq AMIME::Address.new "lucas@example.com"
    v[4].should eq caramel

    e = AMIME::Email.new
    e.add_from "lucas@example.com", caramel

    v = e.from
    v.size.should eq 2
    v[0].should eq AMIME::Address.new "lucas@example.com"
    v[1].should eq caramel

    e = AMIME::Email.new
    e.from "lucas@example.com"
    e.from caramel

    v = e.from
    v.size.should eq 1
    v[0].should eq caramel
  end

  def test_reply_to : Nil
    e = AMIME::Email.new
    helene = AMIME::Address.new "helene@example.com"
    thomas = AMIME::Address.new "thomas@example.com"
    caramel = AMIME::Address.new "caramel@example.com"

    e.reply_to "fred@example.com", helene, thomas

    v = e.reply_to
    v.size.should eq 3
    v[0].should eq AMIME::Address.new "fred@example.com"
    v[1].should eq helene
    v[2].should eq thomas

    e.add_reply_to "lucas@example.com", caramel

    v = e.reply_to
    v.size.should eq 5
    v[0].should eq AMIME::Address.new "fred@example.com"
    v[1].should eq helene
    v[2].should eq thomas
    v[3].should eq AMIME::Address.new "lucas@example.com"
    v[4].should eq caramel

    e = AMIME::Email.new
    e.add_reply_to "lucas@example.com", caramel

    v = e.reply_to
    v.size.should eq 2
    v[0].should eq AMIME::Address.new "lucas@example.com"
    v[1].should eq caramel

    e = AMIME::Email.new
    e.reply_to "lucas@example.com"
    e.reply_to caramel

    v = e.reply_to
    v.size.should eq 1
    v[0].should eq caramel
  end

  def test_to : Nil
    e = AMIME::Email.new
    helene = AMIME::Address.new "helene@example.com"
    thomas = AMIME::Address.new "thomas@example.com"
    caramel = AMIME::Address.new "caramel@example.com"

    e.to "fred@example.com", helene, thomas

    v = e.to
    v.size.should eq 3
    v[0].should eq AMIME::Address.new "fred@example.com"
    v[1].should eq helene
    v[2].should eq thomas

    e.add_to "lucas@example.com", caramel

    v = e.to
    v.size.should eq 5
    v[0].should eq AMIME::Address.new "fred@example.com"
    v[1].should eq helene
    v[2].should eq thomas
    v[3].should eq AMIME::Address.new "lucas@example.com"
    v[4].should eq caramel

    e = AMIME::Email.new
    e.add_to "lucas@example.com", caramel

    v = e.to
    v.size.should eq 2
    v[0].should eq AMIME::Address.new "lucas@example.com"
    v[1].should eq caramel

    e = AMIME::Email.new
    e.to "lucas@example.com"
    e.to caramel

    v = e.to
    v.size.should eq 1
    v[0].should eq caramel
  end

  def test_cc : Nil
    e = AMIME::Email.new
    helene = AMIME::Address.new "helene@example.com"
    thomas = AMIME::Address.new "thomas@example.com"
    caramel = AMIME::Address.new "caramel@example.com"

    e.cc "fred@example.com", helene, thomas

    v = e.cc
    v.size.should eq 3
    v[0].should eq AMIME::Address.new "fred@example.com"
    v[1].should eq helene
    v[2].should eq thomas

    e.add_cc "lucas@example.com", caramel

    v = e.cc
    v.size.should eq 5
    v[0].should eq AMIME::Address.new "fred@example.com"
    v[1].should eq helene
    v[2].should eq thomas
    v[3].should eq AMIME::Address.new "lucas@example.com"
    v[4].should eq caramel

    e = AMIME::Email.new
    e.add_cc "lucas@example.com", caramel

    v = e.cc
    v.size.should eq 2
    v[0].should eq AMIME::Address.new "lucas@example.com"
    v[1].should eq caramel

    e = AMIME::Email.new
    e.cc "lucas@example.com"
    e.cc caramel

    v = e.cc
    v.size.should eq 1
    v[0].should eq caramel
  end

  def test_bcc : Nil
    e = AMIME::Email.new
    helene = AMIME::Address.new "helene@example.com"
    thomas = AMIME::Address.new "thomas@example.com"
    caramel = AMIME::Address.new "caramel@example.com"

    e.bcc "fred@example.com", helene, thomas

    v = e.bcc
    v.size.should eq 3
    v[0].should eq AMIME::Address.new "fred@example.com"
    v[1].should eq helene
    v[2].should eq thomas

    e.add_bcc "lucas@example.com", caramel

    v = e.bcc
    v.size.should eq 5
    v[0].should eq AMIME::Address.new "fred@example.com"
    v[1].should eq helene
    v[2].should eq thomas
    v[3].should eq AMIME::Address.new "lucas@example.com"
    v[4].should eq caramel

    e = AMIME::Email.new
    e.add_bcc "lucas@example.com", caramel

    v = e.bcc
    v.size.should eq 2
    v[0].should eq AMIME::Address.new "lucas@example.com"
    v[1].should eq caramel

    e = AMIME::Email.new
    e.bcc "lucas@example.com"
    e.bcc caramel

    v = e.bcc
    v.size.should eq 1
    v[0].should eq caramel
  end

  def test_priority : Nil
    e = AMIME::Email.new
    e.priority.should eq AMIME::Email::Priority::NORMAL

    e.priority :high
    e.priority.should eq AMIME::Email::Priority::HIGH

    e.priority AMIME::Email::Priority.new(123)
    e.priority.should eq AMIME::Email::Priority::NORMAL
  end

  def test_raises_when_body_is_empty : Nil
    expect_raises AMIME::Exception::Logic, "A message must have a text or an HTML part or attachments." do
      AMIME::Email.new.body
    end
  end

  def test_body : Nil
    e = AMIME::Email.new
    e.body = text = AMIME::Part::Text.new "content"
    e.body.should eq text
  end

  def test_generate_body_with_text_only : Nil
    text = AMIME::Part::Text.new "text content"
    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.text "text content"
    e.body.should eq text
    e.text_body.should eq "text content"
  end

  def test_generate_body_with_html_only : Nil
    text = AMIME::Part::Text.new "html content", sub_type: "html"
    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.html "html content"
    e.body.should eq text
    e.html_body.should eq "html content"
  end

  def test_generate_body_with_text_and_html : Nil
    text = AMIME::Part::Text.new "text content"
    html = AMIME::Part::Text.new "html content", sub_type: "html"
    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.text "text content"
    e.html "html content"
    e.body.should eq AMIME::Part::Multipart::Alternative.new(text, html)
  end

  def test_generate_body_with_text_and_html_non_utf8 : Nil
    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.text "text content", "iso-8859-1"
    e.html "html content", "iso-8859-1"

    e.text_charset.should eq "iso-8859-1"
    e.html_charset.should eq "iso-8859-1"

    e.body.should eq AMIME::Part::Multipart::Alternative.new(
      AMIME::Part::Text.new("text content", "iso-8859-1"),
      AMIME::Part::Text.new("html content", "iso-8859-1", "html"),
    )
  end

  def test_geneate_body_with_text_content_and_attachment : Nil
    text, _, file_part, file = self.generate_some_parts

    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.add_part AMIME::Part::Data.new(file)
    e.text "text content"

    e.body.should eq AMIME::Part::Multipart::Mixed.new text, file_part
  end

  def test_geneate_body_with_html_content_and_attachment : Nil
    _, html, file_part, file = self.generate_some_parts

    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.add_part AMIME::Part::Data.new(file)
    e.html "html content"

    e.body.should eq AMIME::Part::Multipart::Mixed.new html, file_part
  end

  def test_geneate_body_with_html_content_and_inlined_image_not_reference : Nil
    _, html, _, _, image_part, image = self.generate_some_parts
    image_part.as_inline

    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.add_part AMIME::Part::Data.new(image).as_inline
    e.html "html content"

    e.body.should eq AMIME::Part::Multipart::Mixed.new(html, image_part)
  end

  def test_geneate_body_attached_file_only : Nil
    _, _, file_part, file = self.generate_some_parts

    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.add_part AMIME::Part::Data.new file

    e.body.should eq AMIME::Part::Multipart::Mixed.new file_part
  end

  def test_geneate_body_inline_image_only : Nil
    _, _, _, _, image_part, image = self.generate_some_parts
    image_part.as_inline

    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.add_part AMIME::Part::Data.new(image).as_inline

    e.body.should eq AMIME::Part::Multipart::Mixed.new image_part
  end

  def test_geneate_body_with_text_and_html_content_and_attachment : Nil
    text, html, file_part, file = self.generate_some_parts

    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.text "text content"
    e.html "html content"
    e.add_part AMIME::Part::Data.new file

    e.body.should eq AMIME::Part::Multipart::Mixed.new(AMIME::Part::Multipart::Alternative.new(text, html), file_part)
  end

  def test_geneate_body_with_text_and_html_content_and_attachment_and_attached_image_not_referenced : Nil
    text, html, file_part, file, image_part, image = self.generate_some_parts

    e = AMIME::Email.new.from("me@example.com").to("you@example.com")
    e.text "text content"
    e.html "html content"
    e.add_part AMIME::Part::Data.new(file)
    e.add_part AMIME::Part::Data.new(image, "test.gif")

    e.body.should eq AMIME::Part::Multipart::Mixed.new(AMIME::Part::Multipart::Alternative.new(text, html), file_part, image_part)
  end

  private def generate_some_parts : {AMIME::Part::Text, AMIME::Part::Text, AMIME::Part::Data, ::File, AMIME::Part::Data, ::File}
    text = AMIME::Part::Text.new "text content"
    html = AMIME::Part::Text.new "html content", sub_type: "html"
    file_part = AMIME::Part::Data.new file = ::File.open "#{__DIR__}/fixtures/mimetypes/test", "r"
    image_part = AMIME::Part::Data.new image = ::File.open "#{__DIR__}/fixtures/mimetypes/test.gif", "r"

    {text, html, file_part, file, image_part, image}
  end
end
