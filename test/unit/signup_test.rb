require File.dirname(__FILE__) + '/../test_helper'
require 'signup'

class SignupTest < Test::Unit::TestCase
  FIXTURES_PATH = File.dirname(__FILE__) + '/../fixtures'
  CHARSET = "utf-8"

  include ActionMailer::Quoting

  def setup
    ActionMailer::Base.delivery_method = :test
    ActionMailer::Base.perform_deliveries = true
    ActionMailer::Base.deliveries = []

    @expected = TMail::Mail.new
    @expected.set_content_type "text", "plain", { "charset" => CHARSET }
  end

  def test_signup
    @expected.subject = encode 'Signup#signup'
    @expected.body    = read_fixture('signup')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Signup.create_signup(@expected.date).encoded
  end

  def test_forgot_password
    @expected.subject = encode 'Signup#forgot_password'
    @expected.body    = read_fixture('forgot_password')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Signup.create_forgot_password(@expected.date).encoded
  end

  def test_account_created
    @expected.subject = encode 'Signup#account_created'
    @expected.body    = read_fixture('account_created')
    @expected.date    = Time.now

    assert_equal @expected.encoded, Signup.create_account_created(@expected.date).encoded
  end

  private
    def read_fixture(action)
      IO.readlines("#{FIXTURES_PATH}/signup/#{action}")
    end

    def encode(subject)
      quoted_printable(subject, CHARSET)
    end
end
