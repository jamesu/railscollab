OPTIONS = {
:initial_user_name        => ENV['RAILSCOLLAB_INITIAL_USER']        || 'admin',
initial_user_displayname: ENV['RAILSCOLLAB_INITIAL_DISPLAYNAME'] || 'Administrator',
:initial_user_password    => ENV['RAILSCOLLAB_INITIAL_PASSWORD']    || 'password',
:initial_user_email       => ENV['RAILSCOLLAB_INITIAL_EMAIL']       || 'better.set.this@localhost',
:initial_company_name     => ENV['RAILSCOLLAB_INITIAL_COMPANY']     || 'Company'
}

def setup
  owner_company = Company.instance_owner
  new_company = false

  # Ensure owner company exists
  if owner_company.nil?
  	puts 'Creating owner company...'
  	owner_company = Company.new(name: OPTIONS[:initial_company_name])
  	owner_company.time_zone = 'UTC'
  	unless owner_company.save
  		puts "\nCouldn't create a new owner company!\n"
  		return
  	end
  	new_company = true
  end

  # Ensure owner user exists
  unless User.where(['users.is_admin = ? AND users.company_id = ?', true, owner_company.id]).first
  	puts 'Creating owner user...'
  	initial_user = User.new(display_name: OPTIONS[:initial_user_displayname], email: OPTIONS[:initial_user_email])
  	initial_user.username = OPTIONS[:initial_user_name]
  	initial_user.password = OPTIONS[:initial_user_password]
  	initial_user.company = Company.first
  	initial_user.is_admin = true
  	initial_user.auto_assign = true
  	initial_user.time_zone = 'UTC'

  	unless initial_user.save
  		puts 'User already exists, attempting to reset...'
  		# Try resetting the password
  		initial_user = User.where(username: OPTIONS[:initial_user_name]).first
  		if initial_user.nil?
  			puts "\nCouldn't create or reset the owner user!\n"
  			return
  		else
  			initial_user.password = OPTIONS[:initial_user_password]
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
  	ImType.create!(name: 'ICQ',    icon: 'icq.gif')
  	ImType.create!(name: 'Skype',  icon: 'skype.gif')
  	ImType.create!(name: 'Jabber', icon: 'jabber.gif')
  end
end

setup