# Load the rails application
require File.expand_path('../application', __FILE__)
require 'config_system'

ConfigSystem.init

# Initialize the rails application
Railscollab::Application.initialize!

ConfigSystem.load_config
