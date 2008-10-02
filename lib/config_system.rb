=begin
RailsCollab
-----------

Copyright (C) 2008 James S Urquhart (jamesu at gmail.com)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
=end

require 'ostruct'
require 'yaml'


module ConfigSystem

# Courtesy of Dmytro Shteflyuk's blog post
  def self.init
    try_libs
    
    # Following for themeable assets
    ActionView::Helpers::AssetTagHelper.module_eval do
       def image_path(source)
         compute_public_path(source, 'themes/#{AppConfig.site_theme}/images')
       end
       alias_method :path_to_image, :image_path
       
       def stylesheet_path(source)
         compute_public_path(source, "themes/#{AppConfig.site_theme}/stylesheets", 'css')
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
    
    # Globalite
    Globalite.locale = AppConfig.default_language.nil? ? 'en-US' : AppConfig.default_language
  end
  
  def self.try_libs
    @@tried_libs ||= false
    return if @@tried_libs
    
    # Try loading gd2
    begin
      require 'gd2'
      AppConfig.no_gd2 = false
    rescue Exception
      AppConfig.no_gd2 = true
    end
    
    # Try loading AWS::S3
    begin
      require 'aws/s3'
      AppConfig.no_s3 = false
    rescue Exception
      AppConfig.no_s3 = true
    end
    
    @@tried_libs = true
  end

end