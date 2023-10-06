ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
  
  def do_test_tags(owm)
    klass = owm.class

    owm.tags = "1,2,3"
    assert_equal "1 2 3", owm.tags_with_spaces
    owm.save!

    msg = klass.where(id: owm.id).first
    assert_equal "1,2,3", msg.tags

    msg.tags = "4,5,6"
    msg.save!

    msg = klass.where(id: owm.id).first
    assert_equal "4,5,6", msg.tags
  end
end
