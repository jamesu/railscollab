#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/environment'

initial_user_name = ENV['RAILSCOLLAB_INITIAL_USER']
initial_user_displayname = ENV['RAILSCOLLAB_INITIAL_DISPLAYNAME']
initial_user_password = ENV['RAILSCOLLAB_INITIAL_PASSWORD']
initial_user_email = ENV['RAILSCOLLAB_INITIAL_EMAIL']
initial_company_name = ENV['RAILSCOLLAB_INITIAL_COMPANY']

initial_user_name ||= 'admin'
initial_user_displayname ||= 'Administrator'
initial_user_password ||= 'password'
initial_user_email ||= 'better.set.this@localhost'
initial_company_name ||= 'Company'

owner_company = Company.owner
new_company = false

# Ensure owner company exists
if owner_company.nil?
	puts 'Creating owner company...'
	owner_company = Company.new(	:name => initial_company_name )
	if not owner_company.save
		puts "\nCouldn't create a new owner company!\n"
		return
	end
	new_company = true
end

# Ensure owner user exists
unless User.find(:first, :conditions => ['is_admin = true AND company_id = ?', owner_company.id])
	puts 'Creating owner user...'
	initial_user = User.new(	:display_name => initial_user_displayname,
								:email => initial_user_email)
	
	initial_user.username = initial_user_name
	initial_user.password = initial_user_password
	initial_user.company = Company.find(:first)
	initial_user.is_admin = true
	initial_user.auto_assign = true
	
	if not initial_user.save
		puts 'User already exists, attempting to reset...'
		# Try resetting the password
		initial_user = User.find(:first, :conditions => ['username = ?', initial_user_name])
		if initial_user.nil?
			puts "\nCouldn't create or reset the owner user!\n"
			return
		else
			initial_user.password = initial_user_password
			initial_user.company_id = owner_company.id
			if not initial_user.save
				puts "\nCouldn't reset the owner user!\n"
				return
			end
		end
	end

	# Owner company must be created by the owner user
	owner_company.created_by = initial_user
	owner_company.updated_by = initial_user
	owner_company.save!
end

# Ensure IM Types are present
if ImType.count == 0
	(ImType.new(:name => 'ICQ', :icon => 'icq.gif')).save!
	(ImType.new(:name => 'AIM', :icon => 'aim.gif')).save!
	(ImType.new(:name => 'MSN', :icon => 'msn.gif')).save!
	(ImType.new(:name => 'Yahoo!', :icon => 'yahoo.gif')).save!
	(ImType.new(:name => 'Skype', :icon => 'skype.gif')).save!
	(ImType.new(:name => 'Jabber', :icon => 'jabber.gif')).save!
end
