require File.dirname(__FILE__) + '/../test_helper'
require 'access_controller'

# Re-raise errors caught by the controller.
class AccessController; def rescue_action(e) raise e end; end

class AccessControllerTest < Test::Unit::TestCase
  def setup
    @controller = AccessController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
