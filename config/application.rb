require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

module Railscollab
  class Application < Rails::Application
    config.encoding = "utf-8"
    config.filter_parameters += [:password]
    config.from_file 'railscollab.yml'
    config.assets.enabled = true
    config.sass.preferred_syntax = :sass
  end
end

require 'authenticated_system'
require 'authentication'
require 'authentication/by_cookie_token'