require 'test/unit'

require 'rubygems'
gem 'mocha'
require 'mocha'

gem 'ruby-openid'
require 'openid'

RAILS_ROOT = File.dirname(__FILE__) unless defined? RAILS_ROOT
require File.dirname(__FILE__) + "/../lib/open_id_authentication"

class OpenIdAuthenticationTest < Test::Unit::TestCase
  def setup
    @controller = Class.new do
      include OpenIdAuthentication
      def params() {} end
    end.new
  end

  def test_authentication_should_fail_when_the_identity_server_is_missing
    open_id_consumer = mock()
    open_id_consumer.expects(:begin).raises(OpenID::OpenIDError)
    @controller.stubs(:open_id_consumer).returns(open_id_consumer)

    @controller.send(:authenticate_with_open_id, "http://someone.example.com") do |result, identity_url|
      assert result.missing?
      assert_equal "Sorry, the OpenID server couldn't be found", result.message
    end
  end

  def test_authentication_should_fail_when_the_identity_server_times_out
    open_id_consumer = mock()
    open_id_consumer.expects(:begin).raises(Timeout::Error, "Identity Server took too long.")
    @controller.stubs(:open_id_consumer).returns(open_id_consumer)

    @controller.send(:authenticate_with_open_id, "http://someone.example.com") do |result, identity_url|
      assert result.missing?
      assert_equal "Sorry, the OpenID server couldn't be found", result.message
    end
  end

  def test_authentication_should_begin_when_the_identity_server_is_present
    @controller.stubs(:open_id_consumer).returns(stub(:begin => true))
    @controller.expects(:begin_open_id_authentication)
    @controller.send(:authenticate_with_open_id, "http://someone.example.com")
  end
end