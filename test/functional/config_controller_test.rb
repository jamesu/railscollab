require File.dirname(__FILE__) + '/../test_helper'
require 'config_controller'

# Re-raise errors caught by the controller.
class ConfigController; def rescue_action(e) raise e end; end

class ConfigControllerTest < Test::Unit::TestCase
  def setup
    @controller = ConfigController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
