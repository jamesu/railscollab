require File.dirname(__FILE__) + '/../test_helper'
require 'time_controller'

# Re-raise errors caught by the controller.
class TimeController; def rescue_action(e) raise e end; end

class TimeControllerTest < Test::Unit::TestCase
  def setup
    @controller = TimeController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
