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
    e.body.should eq AMIME::Part::Alternative.new(text, html)
  end
end
