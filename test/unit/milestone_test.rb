require 'test_helper'

class MilestoneTest < ActiveSupport::TestCase
  fixtures :all

  def test_milestone_tags
    do_test_tags(milestones(:owner_milestone))
  end

  def test_assigned_to
    ms = milestones(:owner_milestone)
    ms.assigned_to = companies(:owner_company)
    Person.create(project: ms.project, user: users(:owner_user))

    assert_nil ms.assigned_to_user_id
    assert_equal companies(:owner_company).id, ms.assigned_to_company_id

    ms.save!

    assert_equal 0, ms.assigned_to_user_id
    assert_equal companies(:owner_company).id, ms.assigned_to_company_id

    ms.assigned_to = users(:owner_user)

    assert_equal users(:owner_user).id, ms.assigned_to_user_id
    assert_nil ms.assigned_to_company_id

    ms.save!

    assert_equal users(:owner_user).id, ms.assigned_to_user_id
    assert_equal 0, ms.assigned_to_company_id
  end

  def test_assigned_to_id
    ms = milestones(:owner_milestone)

    ms.assigned_to_id = "c#{companies(:owner_company).id}"

    assert_equal companies(:owner_company), ms.company
    assert_nil ms.user
    assert_equal "c#{ms.company.id}", ms.assigned_to_id

    ms.assigned_to_id = "#{users(:owner_user).id}"

    assert_nil ms.company
    assert_equal users(:owner_user), ms.user
    assert_equal "#{ms.user.id}", ms.assigned_to_id
  end

  def test_last_edited_by_owner
    owm = milestones(:owner_milestone)
    cwm = milestones(:client_milestone)
    assert_equal true, owm.last_edited_by_owner?
    assert_equal false, cwm.last_edited_by_owner?

    owm.updated_by = users(:client_user)
    assert_equal false, owm.last_edited_by_owner?

    owm.updated_by = users(:owner_user)
    assert_equal true, owm.last_edited_by_owner?
  end

  def test_dates
    owm = milestones(:owner_milestone)

    owm.due_date = Time.now + 1.day + 1.second

    assert_equal true, owm.is_upcoming?
    assert_equal false, owm.is_late?
    assert_equal false, owm.is_today?
    assert_equal 1, owm.days_left
    assert_equal -1, owm.days_late

    owm.due_date = Time.now + 1.second

    assert_equal false, owm.is_upcoming?
    assert_equal false, owm.is_late?
    assert_equal true, owm.is_today?
    assert_equal 0, owm.days_left
    assert_equal 0, owm.days_late

    owm.due_date = Time.now - 1.day - 1.second

    assert_equal false, owm.is_upcoming?
    assert_equal true, owm.is_late?
    assert_equal false, owm.is_today?
    assert_equal -1, owm.days_left
    assert_equal 1, owm.days_late
  end

  def test_completion
  end

  def test_all_assigned_to
  end

  def test_todays_by_user
  end

  def test_late_by_user
  end

  def test_validations
  end
end
