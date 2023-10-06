require 'test_helper'

class MessageTest < ActiveSupport::TestCase
  fixtures :all

  def test_owner_comments_enabled
    op = projects(:owner_project)
    msg = op.messages.new(title: "Test", text: "Test", category: op.categories.first, created_by: users(:owner_user))
    msg.comments_enabled = false
    msg.save!

    assert_equal false, msg.comments_enabled

    msg = op.messages.new(title: "Test", text: "Test", category: op.categories.first, created_by: users(:client_user))
    msg.comments_enabled = false
    msg.save!

    assert_equal true, msg.comments_enabled
  end

  def test_last_edited_by_owner
    owm = messages(:owner_welcome_message)
    cwm = messages(:client_welcome_message)
    assert_equal true, owm.last_edited_by_owner?
    assert_equal false, cwm.last_edited_by_owner?

    owm.updated_by = users(:client_user)
    assert_equal false, owm.last_edited_by_owner?

    owm.updated_by = users(:owner_user)
    assert_equal true, owm.last_edited_by_owner?
  end

  def test_message_tags
    do_test_tags(messages(:owner_welcome_message))
  end
end
