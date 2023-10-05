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
end
