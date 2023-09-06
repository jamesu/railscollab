require 'test_helper'

class CompanyTest < ActiveSupport::TestCase
  fixtures :all

  test "Owner should exist" do
    assert !Company.owner.nil?
  end
  
  test "Default logo" do
    assert !Company.owner.has_logo?
    
    assert_equal Company.owner.logo_url, "/assets/logo.gif"
  end
  
  test "Permissions" do
    # Within owner company
    master_user = Company.owner.created_by
    admin_user = users(:admin_user)
    owner_user = users(:owner_user)
    
    client_company = companies(:client_company)
    client_user = users(:client_user)
    
    # can_be_created_by
    master_can = Ability.new.init(master_user)
    owner_can = Ability.new.init(owner_user)
    admin_can = Ability.new.init(admin_user)
    client_can = Ability.new.init(client_user)
    company_owner_can = Ability.new.init(Company.owner)

    assert master_can.can?(:create_company, User.new), true
    assert_equal owner_can.can?(:create_company, User.new), false
    assert admin_can.can?(:create_company, User.new), false
    assert_equal client_can.can?(:create_company, User.new), false
    
    # can_be_edited_by
    assert master_can.can?(:edit, Company.owner)
    assert_equal owner_can.can?(:edit, Company.owner), false
    assert_equal client_can.can?(:edit, Company.owner), false
    assert master_can.can?(:edit, client_company)
    assert_equal owner_can.can?(:edit, client_company), false
    assert_equal client_can.can?(:edit, client_company), false
    
    # can_be_deleted_by
    assert master_can.can?(:delete, Company.owner)
    assert_equal owner_can.can?(:delete, Company.owner), false
    assert_equal client_can.can?(:delete, Company.owner), false
    assert master_can.can?(:delete, client_company)
    assert_equal owner_can.can?(:delete, client_company), false
    assert_equal client_can.can?(:delete, client_company), false
    
    # client_can_be_added_by
    assert master_can.can?(:add_client, Company.owner)
    assert_equal owner_can.can?(:add_client, Company.owner), false
    assert_equal client_can.can?(:add_client, Company.owner), false
    assert master_can.can?(:add_client, client_company)
    assert_equal owner_can.can?(:add_client, client_company), false
    assert_equal client_can.can?(:add_client, client_company), false
    
    # can_be_removed_by
    assert_equal master_can.can?(:remove, Company.owner), false
    assert_equal owner_can.can?(:remove, Company.owner), false
    assert_equal client_can.can?(:remove, Company.owner), false
    assert master_can.can?(:remove, client_company)
    assert_equal owner_can.can?(:remove, client_company), false
    assert_equal client_can.can?(:remove, client_company), false
    
    # can_be_managed_by
    assert_equal master_can.can?(:manage, Company.owner), false
    assert_equal owner_can.can?(:manage, Company.owner), false
    assert_equal client_can.can?(:manage, Company.owner), false
    assert master_can.can?(:manage, client_company)
    assert_equal owner_can.can?(:manage, client_company), false
    assert_equal client_can.can?(:manage, client_company), false
    
    # cleanup
    admin_user.destroy
    owner_user.destroy
    client_user.destroy
    client_company.destroy
  end

end
