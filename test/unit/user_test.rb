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
  
end
