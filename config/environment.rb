# Be sure to restart your web server when you modify this file.

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '>=2.3.2' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require 'config_system'

::AppConfig = OpenStruct.new()
ConfigSystem.init

# Extensions
require 'railscollab_extras'

# SSL SMTP
begin
require 'smtp-tls'
rescue Exception
end

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.

  # Add additional load paths for your own custom dirs
  config.load_paths += %W( #{RAILS_ROOT}/app/config_handlers )

  # Specify gems that this application depends on.
  config.gem 'actionmailer', :version => '>=2.1.0'
  config.gem 'ferret',       :version => '>=0.11.6'
  config.gem 'icalendar',    :version => '>=1.0.2'
  config.gem 'ruby-openid',  :version => '>=2.1.2', :lib => 'openid'
  config.gem 'acts_as_ferret',    :version => '>=0.4.4'

  # optional gems
  config.gem 'RedCloth',     :version => '>= 4.0.0',   :lib => 'redcloth'

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  config.i18n.load_path += Dir[Rails.root.join('vendor', 'plugins', '*', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de

  config.action_mailer.delivery_method = :smtp
  config.action_mailer.raise_delivery_errors = true
end

require 'smtp_tls'
ActionMailer::Base.smtp_settings = {
  :address  => "smtp.gmail.com",
  :port  => '587',
  :authentication  => :plain,
  :user_name  => "htc@railcs.com",
  :password  => "q1w2e3"
}

require 'acts_as_ferret'
ActsAsFerret.index_dir = "#{RAILS_ROOT}/tmp/index"

ConfigSystem.post_init

# Include your application configuration below

# Merge database & config.yml into AppConfig
ConfigSystem.load_config
