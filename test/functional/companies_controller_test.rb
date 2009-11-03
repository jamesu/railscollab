require 'test_helper'

class CompaniesControllerTest < ActionController::TestCase

  test "Owner should exist" do
    assert !Company.owner.nil?
  end
  
end
