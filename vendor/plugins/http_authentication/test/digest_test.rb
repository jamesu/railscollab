require 'test/unit'
$LOAD_PATH << File.dirname(__FILE__) + '/../lib/'
require 'http_authentication'

class HttpDigestAuthenticationTest < Test::Unit::TestCase
  include HttpAuthentication::Digest
  
  def setup
    @controller = Class.new do
      attr_accessor :headers, :renders
      
      def initialize
        @headers, @renders = {}, []
      end
      
      def request
        Class.new do
          def env
            { 'HTTP_AUTHORIZATION' => HttpAuthentication::Digest.encode_credentials("dhh", "secret") }
          end
        end.new
      end
      
      def render(options)
        self.renders << options
      end
    end.new
  end

  def test_truth
    assert true
  end
end
