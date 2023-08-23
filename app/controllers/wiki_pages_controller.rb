#==
# RailsCollab
# Copyright (C) 2009 Sergio Cambra
# Portions Copyright (C) 2011 James S Urquhart
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

  before_action :process_session
  before_action :find_sidebar_page, :only => [:index, :show]
  after_action  :user_track, :only => [:index, :show]

  before_action :find_wiki_page, :only => [:show, :edit, :update, :destroy]
  before_action :find_main_wiki_page, :only => :index
  before_action :find_wiki_pages, :only => :list

  rescue_from ActiveRecord::RecordNotFound, :with => :not_found
  
  before_action :check_create_permissions, :only => [:new, :create]
  before_action :check_update_permissions, :only => [:edit, :update]
  before_action :check_delete_permissions, :only => :destroy

  def index
    unless @wiki_page.nil?
      @version = @wiki_page
      @versions = @wiki_page.versions.all.reverse!
      render :action => 'show'
    end
  end

  def list
  end

  def new
    @wiki_page = wiki_pages.new(:title_from_id => params[:id])
  end

  def show
    @versions = @wiki_page.versions.all.reverse!
    @version = @wiki_page.versions.find_by_version(params[:version]) if params[:version]
    @version ||= @wiki_page
  end

  def create
    @wiki_page = wiki_pages.new(wiki_page_params.merge(:created_by => @logged_user))

    if @wiki_page.save
      flash[:message] = I18n.t 'wiki_engine.success_creating_wiki_page'
      redirect_to @wiki_page.main ? wiki_pages_path : wiki_page_path(:id => @wiki_page.slug)
    else
      render :action => 'new'
    end
  end

  def edit
  end

  def update
    if @wiki_page.update_attributes(wiki_page_params.merge(:created_by => @logged_user))
      flash[:message] = I18n.t 'wiki_engine.success_updating_wiki_page'
      redirect_to @wiki_page.main ? wiki_pages_path : wiki_page_path(:id => @wiki_page)
    else
      render :action => 'edit'
    end
  end

  def destroy
    @wiki_page.destroy

    flash[:message] = I18n.t 'wiki_engine.success_deleting_wiki_page'
    redirect_to wiki_pages_path
  end

  def preview
    @wiki_page = wiki_pages.new(wiki_page_params)
    @wiki_page.readonly!

    respond_to do |format|
      format.js { render @wiki_page }
    end
  end

  protected

  def wiki_pages
    WikiPage
  end
  
  def find_wiki_page
    @wiki_page = wiki_pages.find(params[:id])
  end

  # Find main wiki page. This is by default used only for index action.
  def find_main_wiki_page
    @wiki_page = wiki_pages.main(@active_project).first
  end

  # Find all wiki pages. This is by default used only for list action.
  def find_wiki_pages
    @wiki_pages = wiki_pages.all
  end

  # This is called when wiki page is not found. By default it display a page explaining
  # that the wiki page does not exist yet and link to create it.
  def not_found
    render :action => 'not_found', :status => :not_found
  end
  
  def check_create_permissions
    authorize! :create_wiki_page, @active_project
  end

  def check_update_permissions
    authorize! :edit, @wiki_page
  end

  def check_delete_permissions
    authorize! :delete, @wiki_page
  end

  def wiki_pages
    @active_project.wiki_pages
  end

  def find_main_wiki_page
    @wiki_page = wiki_pages.main(@active_project).first
  end

  def find_wiki_page
    @wiki_page = wiki_pages.where(:project_id => @active_project.id).find_by_slug(params[:id])
  end
  
  def find_sidebar_page
    @wiki_sidebar = wiki_pages.where(:project_id => @active_project.id).find_by_slug("sidebar") rescue nil
    @content_for_sidebar = @wiki_sidebar.nil? ? nil : 'wiki_sidebar' 
  end

protected

  def wiki_page_params
    params[:wiki_page].nil? ? {} : params[:wiki_page].permit(:title, :content, :project_id)
  end

end
