# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '>=2.1.0' unless defined? RAILS_GEM_VERSION

ENV['TZ'] = 'UTC'

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')
require 'config_system'

Rails::Initializer.run do |config|
  # Specify gems that this application depends on.
  # They can then be installed with "rake gems:install" on new installations.
  config.gem 'actionmailer', :version => '>=2.1.0'
  config.gem 'ferret',       :version => '>=0.11.6'
  config.gem 'icalendar',    :version => '>=1.0.2'
  config.gem 'ruby-openid',  :version => '>=2.1.2', :lib => 'openid'

  # optional gems
  config.gem 'aws-s3',       :version => '>=0.5.1', :lib => 'aws/s3'
  config.gem 'gd2',          :version => '>=1.1.1'
  config.gem 'RedCloth',     :version => '3.0.4',   :lib => 'redcloth' # not v4.0.1 - it's not working (class RedCloth changed to module)

  # Settings in config/environments/* take precedence over those specified here

  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :action_web_service, :action_mailer ]

  # Only load the plugins named here, by default all plugins in vendor/plugins are loaded
  # config.plugins = %W( exception_notification ssl_requirement )

  # Add additional load paths for your own custom dirs
  config.load_paths += %W( #{RAILS_ROOT}/app/config_handlers )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Note: you should change this when deploying!
  config.action_controller.session = { :session_key => "_railscollab_session", :secret => "08230582-5&6+_|~ vcx R918cAO!!||\"~'" }

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
  config.time_zone = 'UTC'

  # See Rails::Configuration for more options
end

# Add new inflection rules using the following format
# (all these examples are active by default):
# Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register "application/x-mobile", :mobile

# Include your application configuration below

# Merge database & config.yml into AppConfig
begin
  ConfigOption.dump_config(AppConfig)
  unless ConfigOverride.common.nil?
    ConfigOverride.common.keys.each do |key|
      AppConfig.send("#{ConfigOverride.common[key]}=", ConfigOverride.common[key])
    end
  end
rescue Exception
end

# ActionMailer stuff
begin
  ActionMailer::Base.delivery_method                 = AppConfig.notification_email_method.to_sym
  ActionMailer::Base.smtp_settings                   = AppConfig.notification_email_smtp
  ActionMailer::Base.smtp_settings['authentication'] = ActionMailer::Base.smtp_settings['authentication'].to_sym
  ActionMailer::Base.sendmail_settings               = AppConfig.notification_email_sendmail
rescue Exception
end

# Theming
ActionController::Base.asset_host = Proc.new { |source|
  if source.starts_with?('/images') or source.starts_with?('/stylesheets')
    AppConfig.use_asset_hosts ? "assets#{rand(3)}.#{AppConfig.asset_hosts_url}/themes/#{AppConfig.site_theme}" : "#{AppConfig.site_url}/themes/#{AppConfig.site_theme}"
  else
    AppConfig.use_asset_hosts ? "assets#{rand(3)}.#{AppConfig.asset_hosts_url}" : "#{AppConfig.site_url}"
  end
}

# Amazon S3
if !AppConfig.no_s3 and AppConfig.file_upload_storage == 'amazon_s3' and !AppConfig.storage_s3_login.nil?
  require 'aws/s3'
  s3_opts = AppConfig.storage_s3_login

  begin
    AWS::S3::Base.establish_connection!(s3_opts)
  rescue
    AppConfig.no_s3 = true
  end
end

# Localisation
Globalite.locale = AppConfig.default_language.nil? ? :en_US : AppConfig.default_language.to_sym

# Ferret search
FERRETABLE_MODELS = %w[Tag Comment ProjectMessage ProjectTime ProjectTask ProjectTaskList ProjectMilestone ProjectFile ProjectFileRevision]

# Extensions
require_dependency 'railscollab_extras'
