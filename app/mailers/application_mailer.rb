class ApplicationMailer < ActionMailer::Base
  default_url_options[:host] = Rails.configuration.railscollab.site_url
end