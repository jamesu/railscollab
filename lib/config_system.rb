#==
# RailsCollab
# Copyright (C) 2007 - 2008 James S Urquhart
# Portions Copyright (C) René Scheibe
# Portions Copyright (C) Ariejan de Vroom
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++

require 'ostruct'
require 'yaml'


module ConfigSystem

# Courtesy of Dmytro Shteflyuk's blog post
  def self.init
    try_libs
    
    # Determine what we are running under
    AppConfig.server = self.detect_server
  end
  
  def self.detect_server
    # For passenger, IN_PHUSION_PASSENGER is key
    is_passenger = (defined?(IN_PHUSION_PASSENGER) and IN_PHUSION_PASSENGER)
    
    # Not sure about fastcgi, but this should do the trick
    is_fastcgi = (Kernel.const_get('RailsFCGIHandler') if defined?(FCGI)) rescue false
    
    # Webrick is require'd only as a last resort
    is_webrick = !defined?(WEBrick).nil?
    
    # For mongrel and thin, seems best to look for instances
    is_mongrel = false
    ObjectSpace.each_object(Mongrel::HttpHandler) { is_mongrel = true; break; } if defined?(Mongrel)
    is_thin = false
    ObjectSpace.each_object(Thin::Runner) { is_thin = true; break; } if defined?(Thin)
    
    # Earlier versions of passenger don't have IN_PHUSION_PASSENGER, so here's a workaround
    unless is_fastcgi or is_mongrel or is_webrick or is_thin
      is_passenger = defined?(Passenger) and Passenger.class == Module
    end
    
    if is_passenger
      :passenger
    elsif is_fastcgi
      :fastcgi
    elsif is_mongrel
      :mongrel
    elsif is_webrick
      :webrick
    elsif is_thin
      :thin
    else
      :unknown
    end
  end
  
  def self.post_init  
    # Following for themeable assets
    ActionView::Helpers::AssetTagHelper.module_eval do
       alias_method :av_image_path, :image_path
       def image_path(source)
         av_image_path("/themes/#{AppConfig.site_theme}/images/#{source}")
       end
       alias_method :path_to_image, :image_path
       
       alias_method :av_stylesheet_path, :stylesheet_path
       def stylesheet_path(source)
         av_stylesheet_path("/themes/#{AppConfig.site_theme}/stylesheets/#{source}")
       end
       alias_method :path_to_stylesheet, :stylesheet_path
    end    
  end
  
  def self.load_overrides
    begin
      override = OpenStruct.new(YAML.load_file("#{RAILS_ROOT}/config/config.override.yml"))
      env_config = override.send(RAILS_ENV)
      override.common.update(env_config) unless env_config.nil?
      
      override
    rescue Exception
      OpenStruct.new()
    end
  end
  
  def self.load_config
    overrides = load_overrides
    
    begin
      ConfigOption.dump_config(AppConfig)
      unless overrides.common.nil?
        overrides.common.keys.each do |key|
          AppConfig.send("#{overrides.common[key]}=", overrides.common[key])
        end
      end
      
      load_sys
    rescue Exception
    end
  end
  
  def self.load_sys
    
    # ActionMailer stuff
    begin
      ActionMailer::Base.delivery_method                 = AppConfig.notification_email_method.to_sym
      ActionMailer::Base.smtp_settings                   = AppConfig.notification_email_smtp.symbolize_keys.delete_if{ |key, value| value.nil? or value.empty? }
      ActionMailer::Base.smtp_settings[:authentication] = ActionMailer::Base.smtp_settings[:authentication].to_sym
      ActionMailer::Base.sendmail_settings               = AppConfig.notification_email_sendmail
    rescue Exception
    end
    
    # Theming
    ActionController::Base.asset_host = AppConfig.use_asset_hosts ? Proc.new { |source|
        "assets#{rand(3)}.#{AppConfig.asset_hosts_url}"
    } : nil
    
    # Globalite
    I18n.locale = I18n.default_locale= AppConfig.default_language.nil? ? 'en-US' : AppConfig.default_language
  end
  
  def self.try_libs
    @@tried_libs ||= false
    return if @@tried_libs
    
    @@tried_libs = true
  end

end
