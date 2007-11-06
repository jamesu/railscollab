require File.dirname(__FILE__) + '/../test_helper'
require 'milestone_controller'

# Re-raise errors caught by the controller.
class MilestoneController; def rescue_action(e) raise e end; end

class MilestoneControllerTest < Test::Unit::TestCase
  def setup
    @controller = MilestoneController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
