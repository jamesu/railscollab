require File.dirname(__FILE__) + '/../test_helper'
require 'task_controller'

# Re-raise errors caught by the controller.
class TaskController; def rescue_action(e) raise e end; end

class TaskControllerTest < Test::Unit::TestCase
  def setup
    @controller = TaskController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
