struct ParameterizedHeaderTest < ASPEC::TestCase
  @lang = "en-us"

  def test_value_is_returned_verbatim : Nil
    header = AMIME::Header::Parameterized.new "content-type", "text/plain"
    header.body.should eq "text/plain"
  end

  def test_parameters_are_appended : Nil
    header = AMIME::Header::Parameterized.new "content-type", "text/plain"
    header["charset"] = "UTF-8"
    header.body_to_s.should eq "text/plain; charset=UTF-8"
  end

  def test_space_in_param_results_in_quoted_string : Nil
    header = AMIME::Header::Parameterized.new "content-type", "attachment"
    header["filename"] = "my file.txt"
    header.body_to_s.should eq "attachment; filename=\"my file.txt\""
  end

  def test_form_data_results_in_quoted_string : Nil
    header = AMIME::Header::Parameterized.new "content-disposition", "form-data"
    header["filename"] = "file.txt"
    header.body_to_s.should eq "form-data; filename=\"file.txt\""
  end

  def test_form_data_utf8 : Nil
    header = AMIME::Header::Parameterized.new "content-disposition", "form-data"
    header["filename"] = "déjà%\"\n\r.txt"
    header.body_to_s.should eq "form-data; filename=\"déjà%%22%0A%0D.txt\""
  end

  def test_long_params_are_broken_into_multiple_attribute_strings : Nil
    value = "a" * 180

    header = AMIME::Header::Parameterized.new "content-disposition", "attachment"
    header["filename"] = value
    header.body_to_s.should eq(
      "attachment; " \
      "filename*0*=UTF-8''#{"a" * 60};\r\n " \
      "filename*1*=#{"a" * 60};\r\n " \
      "filename*2*=#{"a" * 60}"
    )
  end

  def test_encoded_param_data_includes_charset_and_language : Nil
    value = %(#{"a" * 20}\x8F#{"a" * 10})

    header = AMIME::Header::Parameterized.new "content-disposition", "attachment"
    header.charset = "iso-8859-1"
    header.body = "attachment"
    header["filename"] = value
    header.lang = @lang

    header.body_to_s.should eq "attachment; filename*=iso-8859-1'en-us'aaaaaaaaaaaaaaaaaaaa%8Faaaaaaaaaa"
  end
end
