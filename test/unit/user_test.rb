require 'test_helper'

class UserTest < ActiveSupport::TestCase
  fixtures :all

  test "Password change should product random tokens + salt" do
    owner_user = Factory.create(:owner_user)
    
    # Store token,salt and set new password
    orig_token = owner_user.twisted_token
    orig_salt = owner_user.salt
    owner_user.password = owner_user.password_confirmation = 'testing'
    assert owner_user.save
    owner_user.reload
    
    # Actual test
    assert !owner_user.twisted_token_valid?(orig_token)
    assert owner_user.salt != orig_salt
    
    owner_user.destroy
  end
  
  test "Password reset key should be tied to the last login time" do
    owner_user = Factory.create(:owner_user)
    
    reset_key = owner_user.password_reset_key
    assert reset_key == owner_user.password_reset_key
    
    User.authenticate(owner_user.username, 'password')
    owner_user.reload
    assert reset_key != owner_user.password_reset_key
    
    owner_user.destroy
  end
  
  test "IM Values should be created according to available IM Types" do
    # Make some IM Types
    5.times { Factory.create(:im_type) }
    
    owner_user = Factory.create(:owner_user)
    values = owner_user.im_info
    
    # All types present?
    assert_equal values.length, 5
    values.each do |v|
      assert v.value.empty?
      v.value = Faker::Internet.free_email
      assert v.save
    end
    
    # New im type present?
    new_type_id = Factory.create(:im_type).id
    owner_user.reload
    values = owner_user.im_info
    assert_equal values.length, 6
    
    found = false
    values.each do |v|
      if v.im_type_id == new_type_id
        assert v.value.empty?
        found = true
        break
      end
    end
    assert found
    
    ImType.destroy_all
    owner_user.destroy
  end
  
  test "Permissions" do
    master_user = Company.owner.created_by
    admin_user = Factory.create(:admin)
    owner_user = Factory.create(:owner_user)
    
    client_company = Factory.create(:company)
    client_user = Factory.create(:user, :company => client_company)
    
    # can_be_created_by
    assert_equal User.can_be_created_by(admin_user), true
    assert_equal User.can_be_created_by(owner_user), false
    assert_equal User.can_be_created_by(client_user), false
    
    # can_be_deleted_by
    assert_equal master_user.can_be_deleted_by(master_user), false
    assert_equal master_user.can_be_deleted_by(admin_user), false
    assert_equal master_user.can_be_deleted_by(owner_user), false
    assert_equal master_user.can_be_deleted_by(client_user), false
    
    assert_equal admin_user.can_be_deleted_by(master_user), true
    assert_equal admin_user.can_be_deleted_by(admin_user), false
    assert_equal admin_user.can_be_deleted_by(owner_user), false
    assert_equal admin_user.can_be_deleted_by(client_user), false
    
    assert_equal client_user.can_be_deleted_by(admin_user), true
    
    # can_be_viewed_by
    other_client_company = Factory.create(:company)
    other_client_user = Factory.create(:user, :company => other_client_company)
    
    assert_equal owner_user.can_be_viewed_by(client_user), true
    assert_equal client_user.can_be_viewed_by(client_user), true
    assert_equal client_user.can_be_viewed_by(other_client_user), false
    
    other_client_company.destroy
    other_client_user.destroy
    
    # profile_can_be_updated_by
    assert_equal owner_user.profile_can_be_updated_by(owner_user), true
    assert_equal owner_user.profile_can_be_updated_by(client_user), false
    assert_equal client_user.profile_can_be_updated_by(admin_user), true
    assert_equal client_user.profile_can_be_updated_by(owner_user), false
    
    # permissions_can_be_updated_by
    assert_equal master_user.permissions_can_be_updated_by(admin_user), false
    assert_equal owner_user.permissions_can_be_updated_by(owner_user), false
    assert_equal owner_user.permissions_can_be_updated_by(client_user), false
    assert_equal client_user.permissions_can_be_updated_by(admin_user), true
    assert_equal client_user.permissions_can_be_updated_by(owner_user), false
    
    owner_user.destroy
    admin_user.destroy
    client_user.destroy
    client_company.destroy
  end
  
  test "Default Avatar" do
    owner_user = Factory.create(:owner_user)
    assert !owner_user.avatar?
    
    assert !owner_user.avatar_url.match(/http:\/\/gravatar.com\//).nil?
    
    owner_user.destroy
  end
  
  test "Display Name should equal username if blank" do
    owner_user = Factory.create(:owner_user)
    
    assert owner_user.display_name != owner_user.username
    owner_user.display_name = ''
    assert owner_user.display_name == owner_user.username
    
    owner_user.destroy
  end
  
  test "Online users list" do 
    start_count = User.get_online.length
    
    users = []
    5.times { users << Factory.create(:owner_user) }
    
    assert_equal User.get_online.length, start_count
    
    users.each { |u| User.authenticate(u.username, 'password') }
    
    assert_equal User.get_online.length, start_count+5
    
    users.each { |u| u.destroy }
  end
  
  # TODO: all_milestones, todays_milestones, late_milestones, 
  #       is_part_of, member_of, has_all_permissions, has_permission, permissions_for,
  #       *url  
  
end
