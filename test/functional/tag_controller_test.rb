require File.dirname(__FILE__) + '/../test_helper'
require 'tag_controller'

# Re-raise errors caught by the controller.
class TagController; def rescue_action(e) raise e end; end

class TagControllerTest < Test::Unit::TestCase
  def setup
    @controller = TagController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
  end

  # Replace this with your real tests.
  def test_truth
    assert true
  end
end
