# Entire factory set for RailsCollab
# Used for tests

require "faker"

# Companies / Clients

Factory.define :company do |u|
  u.sequence(:client_of) {|n| Company.owner}
  u.sequence(:name) {|n| Faker::Company.name }
  u.sequence(:email) {|n| Faker::Internet.email }
  
  u.sequence(:created_by) {|n| Company.owner.created_by}
end

# Users

Factory.define :user do |u|
  u.sequence(:username) {|n| "#{Faker::Internet.user_name}#{n}" }
  u.sequence(:display_name) {|n| Faker::Name.name }
  u.is_admin false
  u.auto_assign true
  
  u.identity_url ''
  
  u.sequence(:email) {|n| "#{n}#{Faker::Internet.email}" }
  
  u.password 'password'
  u.password_confirmation 'password'
  
  u.association :company, :factory => :company
end

Factory.define :admin, :parent => :user do |u|
  u.sequence(:company) {|n| Company.owner}
  u.is_admin true
end

Factory.define :owner_user, :parent => :user do |u|
  u.sequence(:company) {|n| Company.owner}
  u.is_admin false
end

Factory.define :im_type do |u|
  u.sequence(:name) {|n| Faker::Company.name }
end

