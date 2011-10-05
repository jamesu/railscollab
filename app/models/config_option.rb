#==
# RailsCollab
# Copyright (C) 2007 - 2011 James S Urquhart
# Portions Copyright (C) René Scheibe
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

class ConfigOption < ActiveRecord::Base
  #belongs_to :config_category

  def category
    @config_category ||= ConfigCategory.where(:name => category_name).first
  end

  def display_name
    I18n.t "option_#{self.name}_name"
  end

  def display_description
    I18n.t "option_#{self.name}_description"
  end

  def handler
    return @config_handler unless @config_handler.nil?

    # Grab class...
    begin
      obj = Kernel.const_get(self.config_handler_class)
    rescue Exception
      obj = StringConfigHandler
    end

    # Initialize with current value
    obj = obj.new
    obj.configOption = self
    obj.rawValue = self.value
    @config_handler = obj

    obj
  end

  def handledValue
    obj = self.handler
    obj.rawValue = self.value
    obj.value
  end

  def handledValue=(value)
    obj = self.handler
    obj.value = value
    self.value = obj.rawValue.to_s
  end

  def render(name, options)
    obj = self.handler
    obj.render(name, options)
  end

  def self.dump_config(config)
    options = ConfigOption.all
    options.each do |option|
      config.send("#{option.name}=", option.handledValue)
    end
  end

  def self.load_config(config)
    options = ConfigOption.all
    options.each do |option|
      value = config.send(option.name)
      unless value.nil?
        puts "#{option.name} = #{value}"
        option.handledValue = value
        option.save
      end
    end
  end

  def self.reload_all
    if Rails.configuration.server == :fastcgi
      FileUtils.touch("#{::Rails.root}/public/dispatch.fcgi")
    else
      FileUtils.touch("#{::Rails.root}/tmp/restart.txt")
    end
    
    # Re-load provided we are not running passenger or fastcgi
    # (also there is the dont_reload_config override)
    unless [:passenger, :fastcgi].include? Rails.configuration.server or Rails.configuration.dont_reload_config
      ConfigSystem.load_config
    end
  end
end
