require File.dirname(__FILE__) + '/../test_helper'
require 'basecamp_controller'

# Re-raise errors caught by the controller.
class BasecampController; def rescue_action(e) raise e end; end

class BasecampControllerTest < Test::Unit::TestCase
  def setup
    @controller = BasecampController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
