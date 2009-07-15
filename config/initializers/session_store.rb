# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.

# Note: make sure you have keys in config/app_keys.yml
temp_key_yaml = YAML.load_file("#{RAILS_ROOT}/config/app_keys.yml")
ActionController::Base.session = {
  :key => temp_key_yaml['session'],
  :secret      => temp_key_yaml['secret']
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
