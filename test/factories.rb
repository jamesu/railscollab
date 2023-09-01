# Entire factory set for RailsCollab
# Used for tests

require "faker"

# Companies / Clients

FactoryBot.define do
  factory :company do
    sequence(:client_of) {|n| Company.owner}
    sequence(:name) {|n| Faker::Company.name }
    sequence(:email) {|n| Faker::Internet.email }
    
    sequence(:created_by) { |n| Company.owner.created_by }
  end
end

# Users

FactoryBot.define do
  factory :user do
    sequence(:username) { |n| "#{Faker::Internet.user_name}#{n}" }
    sequence(:display_name) { |n| Faker::Name.name }
    is_admin { false }
    auto_assign { true }
    
    sequence(:email) {|n| "#{n}#{Faker::Internet.email}" }
    
    password { 'password' }
    password_confirmation { 'password' }
    
    association :company, :factory => :company
  end

  factory :admin, :parent => :user do
    sequence(:company) {|n| Company.owner}
    is_admin { true }
  end

  factory :owner_user, :parent => :user do
    sequence(:company) {|n| Company.owner}
    is_admin { false }
  end

  factory :im_type do
    sequence(:name) {|n| Faker::Company.name }
  end
end
