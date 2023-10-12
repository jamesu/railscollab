require 'test_helper'

class UserTest < ActiveSupport::TestCase
  fixtures :all

  test "Password change should product random tokens + salt" do
    owner_user = users(:owner_user)
    
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
    owner_user = users(:owner_user)
    
    reset_key = owner_user.password_reset_key
    assert reset_key == owner_user.password_reset_key
    
    User.authenticate(owner_user.username, 'password')
    owner_user.reload
    assert reset_key != owner_user.password_reset_key
    
    owner_user.destroy
  end
  
  test "Permissions" do
    master_user = Company.owner.created_by
    admin_user = users(:owner_admin_user)
    owner_user = users(:owner_user)
    
    client_company = companies(:client_company)
    client_user = users(:client_user)
    
    # can_be_created_by
    admin_can = Ability.new.init(admin_user)
    master_can = Ability.new.init(master_user)
    owner_can = Ability.new.init(owner_user)
    client_can = Ability.new.init(client_user)

    assert_equal admin_can.can?(:create_user, User.new), true
    assert_equal master_can.can?(:create_user, User.new), true
    assert_equal owner_can.can?(:create_user, User.new), false
    assert_equal client_can.can?(:create_user, User.new), false
    
    # can_be_deleted_by
    assert_equal master_can.can?(:delete, master_user), false
    assert_equal master_can.can?(:delete, admin_user), true # NOTE: admin_user is an admin, not owner
    assert_equal master_can.can?(:delete, owner_user), true
    assert_equal master_can.can?(:delete, client_user), true
    
    assert_equal admin_can.can?(:delete, master_user), false # cant delete master
    assert_equal admin_can.can?(:delete, admin_user), false
    assert_equal admin_can.can?(:delete, owner_user), true
    assert_equal admin_can.can?(:delete, client_user), true
    
    assert_equal client_can.can?(:delete, admin_user), false
    
    # can_be_viewed_by
    other_client_company = companies(:client_company)
    other_client_user = users(:client_user)
    other_client_can = Ability.new.init(other_client_user)
    
    assert_equal client_can.can?(:show, owner_user), true
    assert_equal client_can.can?(:show, client_user), true
    assert_equal other_client_can.can?(:show, other_client_user), true
    
    other_client_company.destroy
    other_client_user.destroy
    
    # profile_can_be_updated_by
    assert_equal owner_can.can?(:update_profile, owner_user), true
    assert_equal client_can.can?(:update_profile, owner_user), false
    assert_equal admin_can.can?(:update_profile, client_user), true
    assert_equal owner_can.can?(:update_profile, client_user), false
    
    # permissions_can_be_updated_by
    assert_equal admin_can.can?(:update_permissions, master_user), false
    assert_equal owner_can.can?(:update_permissions, owner_user), false
    assert_equal client_can.can?(:update_permissions, owner_user), false
    assert_equal admin_can.can?(:update_permissions, client_user), true
    assert_equal owner_can.can?(:update_permissions, client_user), false
    
    owner_user.destroy
    admin_user.destroy
    client_user.destroy
    client_company.destroy
  end
  
  test "Default Avatar" do
    owner_user = users(:owner_user)
    assert !owner_user.avatar.attached?
    
    assert owner_user.avatar_url == '/assets/avatar.gif'
    
    owner_user.destroy
  end
  
  test "Display Name should equal username if blank" do
    owner_user = users(:owner_user)

    assert owner_user.display_name != owner_user.username
    owner_user.display_name = ''
    assert owner_user.display_name == owner_user.username
    
    owner_user.destroy
  end
  
  test "Online users list" do 
    start_count = User.get_online.length
    
    users = []
    5.times do |i|
      u = User.new(company: companies(:owner_company), 
                   display_name: "User #{i}", 
                   username: "user#{i}", 
                   email: "emailtest#{i}@better.set.this.com",
                   password: 'password', password_confirmation: 'password')
      u.save!
      users << u
    end
    
    assert_equal User.get_online.length, start_count
    
    users.each { |u| User.authenticate(u.username, 'password') }
    
    assert_equal User.get_online.length, start_count+5
    
    users.each { |u| u.destroy }
  end
  
  # TODO: all_milestones, todays_milestones, late_milestones, 
  #       is_part_of, member_of, has_all_permissions, has_permission, permissions_for,
  #       *url  
  
end
