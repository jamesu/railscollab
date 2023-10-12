require 'test_helper'

class CompanyTest < ActiveSupport::TestCase
  fixtures :all

  test "Owner should exist" do
    assert !Company.instance_owner.nil?
  end
  
  test "Default logo" do
    assert !Company.instance_owner.has_logo?
    
    assert_equal Company.instance_owner.logo_url, "/assets/logo.gif"
  end
  
  test "Permissions" do
    # Within owner company
    master_user = Company.instance_owner.created_by
    admin_user = users(:admin_user) # should be same as master_user
    owner_user = users(:owner_user)
    
    client_company = companies(:client_company)
    client_user = users(:client_user)
    
    # can_be_created_by
    master_can = Ability.new.init(master_user)
    owner_can = Ability.new.init(owner_user)
    admin_can = Ability.new.init(admin_user)
    client_can = Ability.new.init(client_user)
    company_owner_can = Ability.new.init(Company.instance_owner)

    assert_equal true, master_can.can?(:create_company, User.new) 
    assert_equal false, owner_can.can?(:create_company, User.new) 
    assert_equal true, admin_can.can?(:create_company, User.new) 
    assert_equal false, client_can.can?(:create_company, User.new) 
    
    # can_be_edited_by
    assert_equal true, master_can.can?(:edit, Company.instance_owner) 
    assert_equal false, owner_can.can?(:edit, Company.instance_owner) 
    assert_equal false, client_can.can?(:edit, Company.instance_owner) 
    assert_equal true, master_can.can?(:edit, client_company) 
    assert_equal false, owner_can.can?(:edit, client_company) 
    assert_equal false, client_can.can?(:edit, client_company) 
    
    # can_be_deleted_by
    assert_equal true, master_can.can?(:delete, Company.instance_owner) 
    assert_equal false, owner_can.can?(:delete, Company.instance_owner) 
    assert_equal false, client_can.can?(:delete, Company.instance_owner) 
    assert_equal true, master_can.can?(:delete, client_company) 
    assert_equal false, owner_can.can?(:delete, client_company) 
    assert_equal false, client_can.can?(:delete, client_company) 
    
    # client_can_be_added_by
    assert_equal true, master_can.can?(:add_client, Company.instance_owner) 
    assert_equal false, owner_can.can?(:add_client, Company.instance_owner) 
    assert_equal false, client_can.can?(:add_client, Company.instance_owner) 
    assert_equal true, master_can.can?(:add_client, client_company) 
    assert_equal false, owner_can.can?(:add_client, client_company) 
    assert_equal false, client_can.can?(:add_client, client_company) 
    
    # can_be_removed_by
    assert_equal false, master_can.can?(:remove, Company.instance_owner) 
    assert_equal false, owner_can.can?(:remove, Company.instance_owner) 
    assert_equal false, client_can.can?(:remove, Company.instance_owner) 
    assert_equal true, master_can.can?(:remove, client_company) 
    assert_equal false, owner_can.can?(:remove, client_company) 
    assert_equal false, client_can.can?(:remove, client_company) 
    
    # can_be_managed_by
    assert_equal true, master_can.can?(:manage, Company.instance_owner) 
    assert_equal false, owner_can.can?(:manage, Company.instance_owner) 
    assert_equal false, client_can.can?(:manage, Company.instance_owner) 
    assert_equal true,  master_can.can?(:manage, client_company)
    assert_equal false, owner_can.can?(:manage, client_company) 
    assert_equal false, client_can.can?(:manage, client_company) 
    
    # cleanup
    admin_user.destroy
    owner_user.destroy
    client_user.destroy
    client_company.destroy
  end

  test "is_part_of" do
    project = Project.new(name: "Test", created_by: Company.instance_owner.created_by)
    project.save!

    assert_equal true, Company.instance_owner.is_part_of(project)
    assert_equal false, companies(:client_company).is_part_of(project)

    project.companies << companies(:client_company)
    project.save!
    assert_equal true, companies(:client_company).is_part_of(project)

    project.destroy
  end

  test "users_on_project" do
    project = Project.new(name: "Test", created_by: Company.instance_owner.created_by)
    project.save!

    assert_equal 0, Company.instance_owner.users_on_project(project).count

    project.companies << companies(:client_company)
    project.save!
    assert_equal 0, Company.instance_owner.users_on_project(project).count

    person = Person.new(project: project, user: users(:client_user))
    person.save!
    assert_equal 0, Company.instance_owner.users_on_project(project).count
    assert_equal 1, companies(:client_company).users_on_project(project).count

    project.destroy
  end

  test "auto_assign_users" do
    user = User.new(
      company: companies(:owner_company), 
      username:"auto_assign_test", 
      display_name: "Test", 
      email: "test567@localhost.com", 
      password: 'password', password_confirmation: 'password')
    user.save!

    assert_equal [users(:client_admin).id, users(:client_user).id].sort, companies(:client_company).auto_assign_users.map{|a|a[:id]}

    user.company = companies(:client_company)
    user.auto_assign = true
    user.save!

    assert_equal [users(:client_admin).id, users(:client_user).id, user.id], companies(:client_company).auto_assign_users.map{|a|a[:id]}

    user.destroy
  end

  def test_validations
  end

end
