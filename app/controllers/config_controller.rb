=begin
RailsCollab
-----------
Copyright (C) 2007 - 2008 James S Urquhart (jamesu at gmail.com)This program is free software; you can redistribute it and/ormodify it under the terms of the GNU General Public Licenseas published by the Free Software Foundation; either version 2of the License, or (at your option) any later version.This program is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied warranty ofMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See theGNU General Public License for more details.You should have received a copy of the GNU General Public Licensealong with this program; if not, write to the Free SoftwareFoundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
=end

class ConfigController < ApplicationController
  layout 'administration'
  
  before_filter :process_session
  
  def update_category
    begin
      @category = ConfigCategory.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_category)
      redirect_to :controller => 'administration', :action => 'configuration'
      return false
    end
    
    if @category.options.empty?
      error_status(true, :config_category_empty)
      redirect_to :controller => 'administration', :action => 'configuration'
    end
    
    @content_for_sidebar = 'update_category_sidebar'
    @options = @category.options
    sys_conds = (params[:system].to_i == 1) ? [] : ['is_system = ?', false]
    @categories = ConfigCategory.find(:all, :conditions => sys_conds, :order => 'category_order DESC')
    
    case request.method
      when :post
      	option_values = params[:options]
      	
      	@options.each do |option|
      		if option_values.has_key? option.name
      			option.value = option_values[option.name]
      			option.save
      		end
      	end
      	
      	# Force reload of configuration
      	ConfigOption.reload_all
      	
        error_status(false, :success_updated_config_category)
        redirect_to :controller => 'administration', :action => 'configuration'
    end
  end
  
  def authorize?(user)
  	return user.is_admin
  end
  
end
