require File.dirname(__FILE__) + '/../test_helper'
require 'form_controller'

# Re-raise errors caught by the controller.
class FormController; def rescue_action(e) raise e end; end

class FormControllerTest < Test::Unit::TestCase
  def setup
    @controller = FormController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
