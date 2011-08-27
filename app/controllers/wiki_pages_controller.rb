#==
# RailsCollab
# Copyright (C) 2009 Sergio Cambra
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

class WikiPagesController < ApplicationController
  layout 'project_website'

  before_filter :process_session
  before_filter :set_created_by, :only => [:create, :update]
  before_filter :find_sidebar_page, :only => [:index, :show]
  after_filter  :user_track, :only => [:index, :show]

  include WikiEngine::Controller
  before_filter :check_create_permissions, :only => [:new, :create]
  before_filter :check_update_permissions, :only => [:edit, :update]
  before_filter :check_delete_permissions, :only => :destroy

  protected
  def check_create_permissions
    authorize! :create_wiki_page, @active_project
  end

  def check_update_permissions
    authorize! :edit, @wiki_page
  end

  def check_delete_permissions
    authorize! :delete, @wiki_page
  end

  def set_created_by
    params[:wiki_page][:created_by] = @logged_user
  end

  def wiki_pages
    @active_project.wiki_pages
  end

  def find_main_wiki_page
    @wiki_page = wiki_pages.main(@active_project).first
  end

  def find_wiki_page
    @wiki_page = wiki_pages.find(params[:id], :scope => @active_project.id.to_s)
  end
  
  def find_sidebar_page
    @wiki_sidebar = wiki_pages.find("sidebar", :scope => @active_project.id.to_s) rescue nil
    @content_for_sidebar = @wiki_sidebar.nil? ? nil : 'wiki_sidebar' 
  end
end
