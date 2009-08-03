#==
# RailsCollab
# Copyright (C) 2007 - 2008 James S Urquhart
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

class ConfigurationsController < ApplicationController
  layout 'administration'

  before_filter :process_session
  before_filter :find_categories
  before_filter :find_category, :only => [:edit, :update]

  def index 
  end

  def edit
    @content_for_sidebar = 'edit_sidebar'
  end

  def update
    option_values = params[:options]

    @options.each do |option|
      next unless option_values.has_key? option.name

      option.value = option_values[option.name]
      option.save
    end

    # Force reload of configuration
    ConfigOption.reload_all

    error_status(false, :success_updated_config_category)
    redirect_to configurations_path
  end

  protected
  def find_categories
    sys_conds = params[:system] ? [] : ['is_system = ?', false]
    @categories = ConfigCategory.all(:conditions => sys_conds, :order => 'category_order DESC')
  end

  def find_category
    begin
      @category = ConfigCategory.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_category)
      redirect_to configurations_path
      return false
    end

    @options = @category.options
    if @options.empty?
      error_status(true, :config_category_empty)
      redirect_to configurations_path
    end
  end

  def authorize?(user)
  	user.is_admin
  end
end
