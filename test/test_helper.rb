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

    do_test_tag_deletion(owm)
  end

  def do_test_tag_deletion(object)
    assert_not_equal 0, object.tag_list.length

    kl = object.dup
    kl.id = nil
    kl.tags = "10,11,12,13"
    kl.save!

    assert_equal 4, Tag.list_by_object(kl).length

    copy = kl.dup
    kl.destroy

    assert_equal 0, Tag.list_by_object(copy).length
  end
end
