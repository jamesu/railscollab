require 'test_helper'

class ProjectTest < ActiveSupport::TestCase
  fixtures :all

  def test_multiple_companies
    project = Project.new(name: "Test", created_by: User.first, companies: Company.all)
    project.save!

    assert_equal 2, project.companies.length
    project.destroy
  end

  def test_milestones_by_user
    project = Project.new(name: "Test", created_by: User.first, companies: Company.all)
    project.save!

    person = Person.new(user: User.first, project: project)
    person.save!
    project.reload

    milestone = project.milestones.new(name: "foo", created_by: User.first)
    milestone.save!

    assert_equal [milestone], project.milestones_by_user(User.first)

    milestone.company = User.first.company
    milestone.save!

    assert_equal [milestone], project.milestones_by_user(User.first)

    milestone.company = companies(:client_company)
    milestone.save!

    assert_equal [], project.milestones_by_user(User.first)

    milestone.assigned_to_company_id = 0
    milestone.assigned_to_user_id = User.first.id
    milestone.save!

    assert_equal [milestone], project.milestones_by_user(User.first)

    project.destroy
  end

  def test_tasks_by_user
    project = Project.new(name: "Test", created_by: User.first, companies: Company.all)
    project.save!

    person = Person.new(user: User.first, project: project)
    person.save!
    project.reload

    list = project.task_lists.new(name: "foo", created_by: User.first)
    list.save!

    task = list.tasks.new(text: "Do this", created_by: User.first)
    task.save!

    assert_equal [task], project.tasks_by_user(User.first)

    task.company = User.first.company
    task.save!

    assert_equal [task], project.tasks_by_user(User.first)

    task.company = companies(:client_company)
    task.save!

    assert_equal [], project.tasks_by_user(User.first)

    task.assigned_to_company_id = 0
    task.assigned_to_user_id = User.first.id
    task.save!

    assert_equal [task], project.tasks_by_user(User.first)

    project.destroy
  end

  def test_audit_log
    start_count = Activity.count

    project = Project.new(name: "Test", created_by: User.first, companies: Company.all)
    project.save!

    assert_equal project, Activity.last.rel_object
    assert_equal :add, Activity.last.action

    project = Project.where(id: project.id).first
    project.updated_by = User.first
    project.name = "Test 2"
    project.save!

    assert_equal project, Activity.last.rel_object
    assert_equal :edit, Activity.last.action

    project.set_completed(true, User.first)
    project.save!

    assert_equal project, Activity.last.rel_object
    assert_equal :close, Activity.last.action
    assert_equal User.first, Activity.last.created_by

    project.destroy

    assert_equal start_count+1, Activity.count
  end

  def test_validations
  end

  # Tests related to perms on ApplicationRecord

  def test_reset_perm_with_uid_list
    pr = projects(:client_project)
    pr.companies << Company.instance_owner
    pr.save!

    ouser = users(:owner_user)
    ouser2 = users(:owner_user2)

    pr.reset_perm_with_uid_list(
    {
      "#{pr.id}_#{ouser.id}" => 0x20, 
    }, [[pr.id, ouser.id]],
    pr.people)

    pr.people.reload
    assert_equal 1, pr.people.count
    assert_equal ouser.id, pr.people.all[0].user_id
    assert_equal 0x20, pr.people.all[0].code
    pr.people.reload

    pr.reset_perm_with_uid_list(
    {
      "#{pr.id}_#{ouser.id}" => 0x20, 
    }, [[pr.id, ouser.id], [pr.id, ouser2.id]],
    pr.people)

    assert_equal 2, pr.people.count
    assert_equal [ouser.id, ouser2.id].sort, pr.people.all.map(&:user_id).sort
    assert_equal [0x0, 0x20].sort, pr.people.all.map(&:code).sort
  end

  def test_make_perm_uid_lists
    list = %w{10_20_can_manage_milestones 10_20_can_manage_messages 10_20_member 20_30_can_manage_files 20_30_member 20_31_can_manage_files 20_31_can_assign_to_owners 20_31_member 20_32_can_assign_to_owners}

    perm_list, uid_list = Project.new.make_perm_uid_lists(list, 20, nil)

    assert_equal 2, uid_list.size
    assert_equal [[20, 30], [20, 31]], uid_list
    assert_equal ['20_30', '20_31', '20_32'], perm_list.keys
    assert_equal (0x20), perm_list['20_30']
    assert_equal (0x20 | 0x40), perm_list['20_31']

    perm_list, uid_list = Project.new.make_perm_uid_lists(list, 10, nil)

    assert_equal 1, uid_list.size
    assert_equal [[10, 20]], uid_list
    assert_equal ['10_20'], perm_list.keys
    assert_equal (0x4 | 0x1), perm_list['10_20']

    perm_list, uid_list = Project.new.make_perm_uid_lists(list, nil, 20)

    assert_equal 1, uid_list.size
    assert_equal [[10, 20]], uid_list
    assert_equal ['10_20'], perm_list.keys
    assert_equal (0x4 | 0x1), perm_list['10_20']
  end

  def test_set_perm_list
    pr = projects(:client_project)
    pr.companies << Company.instance_owner
    pr.save!

    ouser = users(:owner_user)
    ouser2 = users(:owner_user2)

    list_s = [
      [pr.id, ouser.id, :can_manage_milestones], 
      [pr.id, ouser.id, :can_manage_messages],
      [pr.id, ouser.id, :member],
      [pr.id, ouser2.id, :can_manage_files],
      [pr.id, ouser2.id, :can_assign_to_owners]
    ].map{ |a| a.map(&:to_s).join('_') }

    pr.set_perm_list(list_s, pr.id, nil)
    pr.people.reload

    assert_equal 1, pr.people.count
    assert_equal ouser.id, pr.people[0].user_id
    assert_equal (0x4 | 0x1), pr.people[0].code
  end
end
