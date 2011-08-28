#==
# RailsCollab
# Copyright (C) 2007 - 2009 James S Urquhart
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

class FilesController < ApplicationController

  layout 'project_website'
  helper 'project_items'

  before_filter :process_session
  before_filter  :obtain_file, :except => [:index, :new, :create]
  after_filter  :user_track, :only => [:index, :show]
  
  # GET /files
  # GET /files.xml
  def index
    file_conditions = {'project_id' => @active_project.id, 'is_visible' => true}
    file_conditions['is_private'] = false unless @logged_user.member_of_owner?
    
    sort_type = params[:orderBy]
    
    if ['filename'].include?(params[:orderBy])
      sort_order = 'ASC'
    else
      sort_type = 'created_on'
      sort_order = 'DESC'
    end
    
    @current_folder = nil
    @order = sort_type
    
    respond_to do |format|
      format.html {
        @content_for_sidebar = 'index_sidebar'
    
        @page = params[:page].to_i
        @page = 1 unless @page > 0
        
        result_set, @files = ProjectFile.find_grouped(sort_type, :conditions => file_conditions, :page => @page, :per_page => Rails.configuration.files_per_page, :order => "#{sort_type} #{sort_order}")
        @pagination = []
        result_set.total_pages.times {|page| @pagination << page+1}
        
        # Important files and folders (html only)
        @important_files = @active_project.project_files.important(@logged_user.member_of_owner?)
        @folders = @active_project.project_folders
      }
      format.xml  {
        @files = ProjectFile.where(file_conditions)
                            .offset(params[:offset])
                            .limit(params[:limit] || Rails.configuration.files_per_page)
        
        render :xml => @files.to_xml(:only => [:id,
                                               :filename,
                                               :created_by_id, 
                                               :created_on,
                                               :updated_on,
                                               :is_private,
                                               :is_important,
                                               :is_locked,
                                               :comments_count, 
                                               :comments_enabled], :root => 'files')
      }
    end
  end

  # GET /files/1
  # GET /files/1.xml
  def show
    authorize! :show, @file
    
    respond_to do |format|
      format.html {
        @revisions = @file.project_file_revisions
        
        if @revisions.empty?
          error_status(true, :no_file_revisions)
          redirect_back_or_default files_path
        end
        
        @content_for_sidebar = 'index_sidebar'
        @pagination = []

        @folder = @file.project_folder
        @last_revision = @revisions[0]

        @current_folder = @file.project_folder
        @order = nil
        @page = nil
        @folders = @active_project.project_folders
        
        # Important files (html only)
        @important_files = @active_project.project_files.important(@logged_user.member_of_owner?)
      }
      format.xml  { 
        render :xml => @file.to_xml(:include => [:project_file_revisions])
      }
    end
  end

  # GET /files/new
  # GET /files/new.xml
  def new
    authorize! :create_file, @active_project
    
    @file = @active_project.project_files.build()
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @file.to_xml(:root => 'file') }
    end
  end

  # GET /files/1/edit
  def edit
    authorize! :edit, @file
  end

  # POST /files
  # POST /files.xml
  def create
    authorize! :create_file, @active_project

    file_attribs = params[:file]
    @file = @active_project.project_files.build(file_attribs)
    @file.created_by = @logged_user

    # verify file data
    file_data = params[:file_data]
    if file_data.nil? or file_data[:file].nil?
      @file.errors.add(:file, I18n.t('required'))
    end
    
    # sort out other attributes
    @file.filename = file_data[:file] ? (file_data[:file].original_filename).sanitize_filename : nil
    @file.expiration_time = 0
    @file.is_visible = true

    saved = false

    ProjectFile.transaction do
      saved = @file.save

      if saved
        @file.add_revision(file_data[:file], 1, @logged_user, '')
        @file.tags = file_attribs[:tags]
      end
    end

    respond_to do |format|
      if saved
        format.html {
          error_status(false, :success_added_file)
          redirect_back_or_default(@file)
        }
        format.js {}
        format.xml  { render :xml => @file.to_xml(:root => 'file'), :status => :created, :location => @file }
      else
        format.html { render :action => "new" }
        format.js {}
        format.xml  { render :xml => @file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /files/1
  # PUT /files/1.xml
  def update
    authorize! :edit, @file

    file_data = params[:file_data]
    unless file_data.nil?
      if file_data[:updated_file] and !file_data[:file]
        @file.errors.add(:file, I18n.t('required'))
      end
    end

    file_attribs = params[:file]
    @file.attributes = file_attribs
    @file.updated_by = @logged_user
    @file.is_visible = true
    
    saved = false

    ProjectFile.transaction do
      saved = @file.save
      
      if saved
        if file_data[:updated_file]
          if file_data[:version_file_change]
            @file.add_revision(file_data[:file], @file.project_file_revisions[0].revision_number+1, @logged_user, file_data[:revision_comment])
          else
            @file.update_revision(file_data[:file], @file.project_file_revisions[0], @logged_user, file_data[:revision_comment])
          end

          @file.filename = (file_data[:file].original_filename).sanitize_filename
        end

        @file.tags = file_attribs[:tags]
      end
    end
    
    respond_to do |format|
      if saved
        format.html {
          error_status(false, :success_edited_file)
          redirect_back_or_default(@file)
        }
        format.js {}
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.js {}
        format.xml  { render :xml => @file.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /files/1
  # DELETE /files/1.xml
  def destroy
    authorize! :delete, @file
    
    @file.updated_by = @logged_user
    @file.destroy

    respond_to do |format|
      format.html {
        error_status(false, :success_deleted_file)
        redirect_to files_url
      }
      format.js {}
      format.xml  { head :ok }
    end
  end
  
  # GET /files/1/download
  def download
    revision_id = params[:revision]

    unless revision_id.nil?
      begin
        @file_revision = ProjectFileRevision.first(:conditions => ['file_id = ? AND revision_number = ?', @file.id, revision_id])
      rescue ActiveRecord::RecordNotFound
        error_status(true, :invalid_file_revision)
        redirect_back_or_default files_path
        return
      end
    else
      @file_revision = @file.project_file_revisions[0]
    end

    if @file_revision.nil?
      render :text => '404 Not Found', :status => 404
      return
    end

    if @file_revision.data?
      redirect_to @file_revision.data.url, :status => 302
    else
      render :text => '404 Not Found', :status => 404
    end
  end
  
  # PUT /files/1/attach
  def attach
    rel_object_type = params[:object_type]
    rel_object_id = params[:object_id]

    if (rel_object_type.nil? or rel_object_id.nil?) or (!['Comment', 'ProjectMessage'].include?(rel_object_type))
      error_status(true, :invalid_request)
      redirect_back_or_default :controller => 'files'
      return
    end

    # Find object we want to attach a file to
    begin
      @attach_object = Kernel.const_get(rel_object_type).find(params[:object_id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_object)
      redirect_back_or_default :controller => 'files'
      return
    end

    authorize! :add_file, @attach_object

    case request.method_symbol
    when :put
      attach_attribs = params[:attach]

      if attach_attribs[:what] == 'new_file'
        begin
          ProjectFile.handle_files(params[:uploaded_files], @attach_object, @logged_user, @attach_object.is_private)
          error_status(false, :success_added_new_file_to_object)
        rescue
          error_status(false, :error_adding_file_to_object)
        end

        redirect_back_or_default @attach_object.object_url
        return
      elsif attach_attribs[:what] == 'existing_file'
        begin
          existing_file = @active_project.project_files.find(attach_attribs[:file_id])
        rescue ActiveRecord::RecordNotFound
          error_status(true, :invalid_file)
          redirect_back_or_default @attach_object.object_url
          return
        end

        # Make sure its unique
        does_exist = @attach_object.project_file.any?{ |file| file == existing_file }
        if !does_exist
          AttachedFile.create!(:created_on => existing_file.created_on, 
                               :created_by => @logged_user, 
                               :rel_object => @attach_object, 
                               :project_file => existing_file)
          #@attach_object.project_file << existing_file
        end
        
        error_status(false, :success_added_file_to_object)
        redirect_back_or_default @attach_object.object_url
        return
      end

      error_status(true, :error_adding_file_to_object)
      redirect_back_or_default @attach_object.object_url
      return
    end
  end
  
  # PUT /files/1/detatch
  def detatch
    # params: manager, file_id, object_id
    rel_object_type = params[:object_type]
    rel_object_id = params[:object_id]

    if (rel_object_type.nil? or rel_object_id.nil?) or (!['Comment', 'ProjectMessage'].include?(rel_object_type))
      error_status(true, :invalid_request)
      redirect_back_or_default files_path
      return
    end

    # Find object we want to attach a file to
    begin
      @attach_object = Kernel.const_get(rel_object_type).find(params[:object_id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_object)
      redirect_back_or_default files_path
      return
    end

    authorize! :add_file, @attach_object

    begin
      existing_file = @active_project.project_files.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_file)
      redirect_back_or_default @attach_object.object_url
      return
    end

    AttachedFile.clear_attachment(@attach_object, existing_file.id)

    error_status(false, :success_removed_file_from_object)
    redirect_back_or_default @attach_object.object_url
  end

private

  def obtain_file
     begin
        @file = @active_project.project_files.find(params[:id])
     rescue ActiveRecord::RecordNotFound
       error_status(true, :invalid_file)
       redirect_back_or_default files_path
       return false
     end
     
     return true
  end
  
end
