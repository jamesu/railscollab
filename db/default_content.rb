#!/usr/bin/env ruby
require File.dirname(__FILE__) + '/../config/environment'

initial_user_name        = ENV['RAILSCOLLAB_INITIAL_USER']        || 'admin'
initial_user_displayname = ENV['RAILSCOLLAB_INITIAL_DISPLAYNAME'] || 'Administrator'
initial_user_password    = ENV['RAILSCOLLAB_INITIAL_PASSWORD']    || 'password'
initial_user_email       = ENV['RAILSCOLLAB_INITIAL_EMAIL']       || 'better.set.this@localhost'
initial_company_name     = ENV['RAILSCOLLAB_INITIAL_COMPANY']     || 'Company'
initial_site_url         = ENV['RAILSCOLLAB_SITE_URL']

owner_company = Company.owner
new_company = false

# Ensure owner company exists
if owner_company.nil?
	puts 'Creating owner company...'
	owner_company = Company.new(:name => initial_company_name)
	unless owner_company.save
		puts "\nCouldn't create a new owner company!\n"
		return
	end
	new_company = true
end

# Ensure owner user exists
unless User.first(:conditions => ['users.is_admin = ? AND users.company_id = ?', true, owner_company.id])
	puts 'Creating owner user...'
	initial_user = User.new(:display_name => initial_user_displayname, :email => initial_user_email)
	initial_user.username = initial_user_name
	initial_user.password = initial_user_password
	initial_user.company = Company.first
	initial_user.is_admin = true
	initial_user.auto_assign = true

	unless initial_user.save
		puts 'User already exists, attempting to reset...'
		# Try resetting the password
		initial_user = User.first(:conditions => ['username = ?', initial_user_name])
		if initial_user.nil?
			puts "\nCouldn't create or reset the owner user!\n"
			return
		else
			initial_user.password = initial_user_password
			initial_user.company_id = owner_company.id
			unless initial_user.save
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
	ImType.create!(:name => 'ICQ',    :icon => 'icq.gif')
	ImType.create!(:name => 'AIM',    :icon => 'aim.gif')
	ImType.create!(:name => 'MSN',    :icon => 'msn.gif')
	ImType.create!(:name => 'Yahoo!', :icon => 'yahoo.gif')
	ImType.create!(:name => 'Skype',  :icon => 'skype.gif')
	ImType.create!(:name => 'Jabber', :icon => 'jabber.gif')
end

# Ensure File Types are present
if FileType.count == 0
	FileType.create!(:extension => 'zip',  :icon => 'archive.png', :is_searchable => 0, :is_image => 0)
	FileType.create!(:extension => 'rar',  :icon => 'archive.png', :is_searchable => 0, :is_image => 0)
	FileType.create!(:extension => 'bz',   :icon => 'archive.png', :is_searchable => 0, :is_image => 0)
	FileType.create!(:extension => 'bz2',  :icon => 'archive.png', :is_searchable => 0, :is_image => 0)
	FileType.create!(:extension => 'gz',   :icon => 'archive.png', :is_searchable => 0, :is_image => 0)
	FileType.create!(:extension => 'ace',  :icon => 'archive.png', :is_searchable => 0, :is_image => 0)
	FileType.create!(:extension => 'mp3',  :icon => 'audio.png',   :is_searchable => 0, :is_image => 0)
	FileType.create!(:extension => 'wma',  :icon => 'audio.png',   :is_searchable => 0, :is_image => 0)
	FileType.create!(:extension => 'ogg',  :icon => 'audio.png',   :is_searchable => 0, :is_image => 0)
	FileType.create!(:extension => 'doc',  :icon => 'doc.png',     :is_searchable => 0, :is_image => 0)
	FileType.create!(:extension => 'xsl',  :icon => 'doc.png',     :is_searchable => 0, :is_image => 0)
	FileType.create!(:extension => 'gif',  :icon => 'image.png',   :is_searchable => 0, :is_image => 1)
	FileType.create!(:extension => 'jpg',  :icon => 'image.png',   :is_searchable => 0, :is_image => 1)
	FileType.create!(:extension => 'jpeg', :icon => 'image.png',   :is_searchable => 0, :is_image => 1)
	FileType.create!(:extension => 'png',  :icon => 'image.png',   :is_searchable => 0, :is_image => 1)
	FileType.create!(:extension => 'mov',  :icon => 'mov.png',     :is_searchable => 0, :is_image => 0)
	FileType.create!(:extension => 'pdf',  :icon => 'pdf.png',     :is_searchable => 0, :is_image => 0)
	FileType.create!(:extension => 'psd',  :icon => 'psd.png',     :is_searchable => 0, :is_image => 0)
	FileType.create!(:extension => 'rm',   :icon => 'rm.png',      :is_searchable => 0, :is_image => 0)
	FileType.create!(:extension => 'svg',  :icon => 'svg.png',     :is_searchable => 0, :is_image => 0)
	FileType.create!(:extension => 'swf',  :icon => 'swf.png',     :is_searchable => 0, :is_image => 0)
	FileType.create!(:extension => 'avi',  :icon => 'video.png',   :is_searchable => 0, :is_image => 0)
	FileType.create!(:extension => 'mpeg', :icon => 'video.png',   :is_searchable => 0, :is_image => 0)
	FileType.create!(:extension => 'mpg',  :icon => 'video.png',   :is_searchable => 0, :is_image => 0)
	FileType.create!(:extension => 'qt',   :icon => 'mov.png',     :is_searchable => 0, :is_image => 0)
	FileType.create!(:extension => 'vob',  :icon => 'video.png',   :is_searchable => 0, :is_image => 0)
	FileType.create!(:extension => 'txt',  :icon => 'doc.png',     :is_searchable => 1, :is_image => 0)
end

# Set site_url if available
unless initial_site_url.nil?
    opt = ConfigOption.first(:conditions => ['name = ?', 'site_url'])
    opt.value = initial_site_url
    opt.save
end
