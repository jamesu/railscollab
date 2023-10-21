require 'test_helper'

class PersonTest < ActiveSupport::TestCase
  fixtures :all

  def test_permissions
    pl = %i[
    can_manage_messages
    can_manage_tasks
    can_manage_milestones
    can_manage_time
    can_upload_files
    can_manage_files
    can_assign_to_owners
    can_assign_to_other
    can_manage_wiki_pages]

    person = Person.new()
    person.user = users(:client_user)
    assert_equal true, person.has_all_permissions?

    person.clear_all_permissions
    assert_equal false, person.has_all_permissions?

    person.set_all_permissions
    assert_equal true, person.has_all_permissions?

    pl.each do |key|
      person.set_permission(key, true)
      assert_equal true, person.has_permission(key)
    end

    assert_equal true, person.has_all_permissions?

    person.clear_all_permissions
    person.user = users(:client_admin)

    assert_equal true, person.has_all_permissions?

    person.clear_all_permissions
    assert_equal true, person.has_all_permissions?

    pl.each do |key|
      person.set_permission(key, false)
      assert_equal true, person.has_permission(key)
    end
  end
end
