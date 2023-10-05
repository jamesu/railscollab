require_relative "boot"

require "rails/all"
require "active_storage/engine"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Railscollab
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    config.time_zone = 'UTC'
    config.i18n.default_locale = :en
    config.encoding = "utf-8"
    config.filter_parameters += [:password]

    config.assets.enabled = true
    config.assets.version = '1.0'

    config.generators.stylesheet_engine = :sass

    config.active_job.queue_name_prefix = Rails.env
    config.action_mailer.default_url_options = { host: 'localhost:3000' }
    config.railscollab = config_for(:railscollab)

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end

require 'railscollab_extras'
require 'authenticated_system'
require 'authentication'
require 'authentication/by_cookie_token'
