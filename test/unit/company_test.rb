require 'test_helper'

class CompanyTest < ActiveSupport::TestCase
  fixtures :all

  test "Owner should exist" do
    assert !Company.owner.nil?
  end
  
  test "Default logo" do
    assert !Company.owner.has_logo?
    
    assert_equal Company.owner.logo_url, "/themes/#{AppConfig.site_theme}/images/logo.gif"
  end
  
  test "Permissions" do
    # Within owner company
    master_user = Company.owner.created_by
    admin_user = Factory.create(:admin)
    owner_user = Factory.create(:owner_user)
    
    client_company = Factory.create(:company)
    client_user = Factory.create(:user, :company => client_company)
    
    # can_be_created_by
    assert Company.can_be_created_by(master_user)
    assert_equal Company.can_be_created_by(owner_user), false
    assert Company.can_be_created_by(admin_user)
    assert_equal Company.can_be_created_by(client_user), false
    
    # can_be_edited_by
    assert Company.owner.can_be_edited_by(master_user)
    assert_equal Company.owner.can_be_edited_by(owner_user), false
    assert_equal Company.owner.can_be_edited_by(client_user), false
    assert client_company.can_be_edited_by(master_user)
    assert_equal client_company.can_be_edited_by(owner_user), false
    assert_equal client_company.can_be_edited_by(client_user), false
    
    # can_be_deleted_by
    assert Company.owner.can_be_deleted_by(master_user)
    assert_equal Company.owner.can_be_deleted_by(owner_user), false
    assert_equal Company.owner.can_be_deleted_by(client_user), false
    assert client_company.can_be_deleted_by(master_user)
    assert_equal client_company.can_be_deleted_by(owner_user), false
    assert_equal client_company.can_be_deleted_by(client_user), false
    
    # client_can_be_added_by
    assert Company.owner.client_can_be_added_by(master_user)
    assert_equal Company.owner.client_can_be_added_by(owner_user), false
    assert_equal Company.owner.client_can_be_added_by(client_user), false
    assert client_company.client_can_be_added_by(master_user)
    assert_equal client_company.client_can_be_added_by(owner_user), false
    assert_equal client_company.client_can_be_added_by(client_user), false
    
    # can_be_removed_by
    assert_equal Company.owner.can_be_removed_by(master_user), false
    assert_equal Company.owner.can_be_removed_by(owner_user), false
    assert_equal Company.owner.can_be_removed_by(client_user), false
    assert client_company.can_be_removed_by(master_user)
    assert_equal client_company.can_be_removed_by(owner_user), false
    assert_equal client_company.can_be_removed_by(client_user), false
    
    # can_be_managed_by
    assert_equal Company.owner.can_be_managed_by(master_user), false
    assert_equal Company.owner.can_be_managed_by(owner_user), false
    assert_equal Company.owner.can_be_managed_by(client_user), false
    assert client_company.can_be_managed_by(master_user)
    assert_equal client_company.can_be_managed_by(owner_user), false
    assert_equal client_company.can_be_managed_by(client_user), false
    
    # cleanup
    admin_user.destroy
    owner_user.destroy
    client_user.destroy
    client_company.destroy
  end

end
