require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Railscollab
  class Application < Rails::Application
    config.encoding = "utf-8"
    config.filter_parameters += [:password]
    
    def config.from_file(file)
      super
      
      self.i18n.default_locale = default_language
      
      # Configure mailer
      self.action_mailer.default_url_options = { :host => URI.parse(site_url).host }
      self.action_mailer.delivery_method                 = notification_email_method.to_sym
      self.action_mailer.smtp_settings                   = notification_email_smtp.symbolize_keys.delete_if{ |key, value| value.nil? or value.to_s.empty? }
      self.action_mailer.smtp_settings[:authentication]  = self.action_mailer.smtp_settings[:authentication].to_sym
      self.action_mailer.sendmail_settings               = Rails.configuration.notification_email_sendmail
    end
      
    config.from_file 'railscollab.yml'
    config.assets.enabled = true
    config.sass.preferred_syntax = :sass
  end
  
  def self.config
    Rails.configuration
  end
end

require 'authenticated_system'
require 'authentication'
require 'authentication/by_cookie_token'
require 'railscollab_extras'