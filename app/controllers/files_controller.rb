=begin
RailsCollab
-----------

Copyright (C) 2007 - 2008 James S Urquhart (jamesu at gmail.com)

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

class FilesController < ApplicationController

  layout 'project_website'
  
  verify :method => :post,
  		 :only => [ :delete_folder, :delete_file, :detatch_from_object ],
  		 :add_flash => { :error => true, :message => :invalid_request.l },
         :redirect_to => { :controller => 'file', :action => 'index' }
  
  filter_parameter_logging :file_data

  before_filter :process_session, :except => [:thumbnail]
  before_filter :accept_folder_name, :only => [:browse_folder, :edit_folder, :delete_folder]
  after_filter  :user_track, :only => [:index, :browse_folder]

  # Caching
  caches_page :thumbnail
  cache_sweeper :files_sweeper, :only => [ :add_file, :edit_file, :delete_file ]
    
  def index
    current_page = params[:page].to_i
    current_page = 0 unless current_page > 0
    
    file_conditions = {'project_id' => @active_project.id, 'is_visible' => true}
    file_conditions['is_private'] = true unless @logged_user.member_of_owner?
    
    sort_type = params[:orderBy]
    sort_type = 'created_on' unless ['filename'].include?(params[:orderBy])
    sort_order = 'DESC'
    
    result_set, @files = ProjectFile.find_grouped(sort_type, :conditions => file_conditions, :page => {:size => AppConfig.files_per_page, :current => current_page}, :order => "#{sort_type} #{sort_order}")
    @pagination = []
    result_set.page_count.times {|page| @pagination << page+1}
    
    @current_folder = nil
    @order = sort_type
    @page = current_page
    @folders = @active_project.project_folders
    @important_files = @active_project.project_files.important(@logged_user.member_of_owner?)
    
    @content_for_sidebar = 'index_sidebar'
  end
  
  # Folders
  
  def browse_folder
    begin
      @folder ||= @active_project.project_folders.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_folder)
      redirect_back_or_default :controller => 'files'
      return
    end
    
    if !@folder.can_be_seen_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'files'
    end
    
    current_page = params[:page].to_i
    current_page = 0 unless current_page > 0
    
    file_conditions = {'folder_id' => @folder.id, 'project_id' => @active_project.id, 'is_visible' => true}
    file_conditions['is_private'] = true unless @logged_user.member_of_owner?
    
    sort_type = params[:orderBy]
    sort_type = 'created_on' unless ['filename'].include?(params[:orderBy])
    sort_order = 'DESC'

    result_set, @files = ProjectFile.find_grouped(sort_type, :conditions => file_conditions, :page => {:size => AppConfig.files_per_page, :current => current_page}, :order => "#{sort_type} #{sort_order}")
    @pagination = []
    result_set.page_count.times {|page| @pagination << page+1}
    
    @current_folder = @folder
    @order = sort_type
    @page = current_page
    @folders = @active_project.project_folders
    @important_files = @active_project.project_files.important(@logged_user.member_of_owner?)
       
    @content_for_sidebar = 'index_sidebar'
    
    render :template => 'files/index'
  end
  
  def add_folder
    @folder = ProjectFolder.new
    
    if not ProjectFolder.can_be_created_by(@logged_user, @active_project)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'files'
      return
    end
    
    case request.method
      when :post
        folder_attribs = params[:folder]
        
        @folder.attributes = folder_attribs
        
        @folder.project = @active_project
        
        if @folder.save
          ApplicationLog::new_log(@folder, @logged_user, :add)
          
          error_status(false, :success_added_folder)
          redirect_back_or_default :controller => 'files'
        end
    end
  end
  
  def edit_folder
    begin
      @folder ||= @active_project.project_folders.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_folder)
      redirect_back_or_default :controller => 'files'
      return
    end
    
    if not @folder.can_be_edited_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'files'
      return
    end
    
    case request.method
      when :post
        folder_attribs = params[:folder]
        
        @folder.attributes = folder_attribs
        
        if @folder.save
          ApplicationLog::new_log(@folder, @logged_user, :edit)
          
          error_status(false, :success_edited_folder)
          redirect_back_or_default :controller => 'files'
        end
    end
  end
  
  def delete_folder
    begin
      @folder ||= @active_project.project_folders.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_folder)
      redirect_back_or_default :controller => 'files'
      return
    end
    
    if not @folder.can_be_deleted_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'files'
      return
    end
    
    ApplicationLog::new_log(@folder, @logged_user, :delete)
    @folder.destroy
    
    error_status(false, :success_deleted_folder)
    redirect_back_or_default :controller => 'files'
  end
  
  # Files
  
  def file_details
    begin
      @file ||= @active_project.project_files.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_file)
      redirect_back_or_default :controller => 'files'
      return
    end
    
    if !@file.can_be_seen_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'files'
    end
    
    @revisions = @file.project_file_revisions
    if @revisions.length == 0
      error_status(true, :no_file_revisions)
      redirect_back_or_default :controller => 'files'
    end
    
    @pagination = []
    
    @folder = @file.project_folder
    @revisions = @file.project_file_revisions
    @last_revision = @revisions[0]
    
    @current_folder = @file.project_folder
    @order = nil
    @page = nil
    @folders = @active_project.project_folders
    @important_files = @active_project.project_files.important(@logged_user.member_of_owner?)
       
    @content_for_sidebar = 'index_sidebar'
  end
  
  def download_file
    begin
      @file ||= @active_project.project_files.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_file)
      redirect_back_or_default :controller => 'files'
      return
    end
    
    revision_id = params[:revision]
    
    if !revision_id.nil?
	    begin
	      @file_revision = ProjectFileRevision.find(:first, :conditions => ['file_id = ? AND revision_number = ?', @file.id, revision_id])
	    rescue ActiveRecord::RecordNotFound
	      error_status(true, :invalid_file_revision)
	      redirect_back_or_default :controller => 'files'
	      return
	    end
	else
		@file_revision = @file.project_file_revisions[0]
    end
    
    if @file_revision.nil?
    	render :text => '404 Not Found', :status => 404
		return
    end
    
    content_data = FileRepo.get_data(@file_revision.repository_id)
    
    if !content_data.nil?
        if content_data.class == Hash
           redirect_to content_data[:url], :status => 302
        else
    	   send_data content_data, :type => @file_revision.type_string, :filename => @file.filename, :length => @file_revision.filesize
    	end
    else
    	render :text => '404 Not Found', :status => 404
    end
  end
  
  def add_file
    @file = ProjectFile.new
    
    if not ProjectFile.can_be_created_by(@logged_user, @active_project)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'files'
      return
    end
    
    case request.method
      when :get
	    if params[:folder_name]
		    begin
		      @folder = @active_project.project_folders.find(:first, :conditions => ['name = ?', params[:folder_name]])
		    rescue ActiveRecord::RecordNotFound
		    end
		elsif params[:folder_id]
		    begin
		      @folder = @active_project.project_folders.find(params[:folder_id])
		    rescue ActiveRecord::RecordNotFound
		    end
	    end
    
      	@file.project_folder = @folder unless @folder.nil?
	    @file.comments_enabled = true unless (params[:file] and params[:file].has_key?(:comments_enabled))
      when :post
        file_attribs = params[:file]
        file_data = params[:file_data]
        
        if file_data.nil? or file_data[:file].nil?
        	@file.errors.add(:file, :required.l)
        end
        
        do_abort = !@file.errors.empty?
        
        @file.attributes = file_attribs
        
        @file.created_by = @logged_user
        @file.project = @active_project
        @file.filename = file_data[:file] ? (file_data[:file].original_filename).sanitize_filename : nil
        @file.expiration_time = 0
        @file.is_visible = true
        
        ProjectFile.transaction do
	        if @file.save
	          @file.add_revision(file_data[:file], 1, @logged_user, "")
	          
	          @file.tags = file_attribs[:tags]
	          
	          error_status(false, :success_added_file)
	          redirect_back_or_default :controller => 'files'
	        end
        end
    end
  end
  
  def edit_file
    begin
      @file = @active_project.project_files.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_file)
      redirect_back_or_default :controller => 'files'
      return
    end
    
    if not @file.can_be_edited_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'files'
      return
    end
    
    case request.method
      when :post
        file_attribs = params[:file]
        file_data = params[:file_data]
        
        if !file_data.nil?
        	if file_data[:updated_file] and !file_data[:file]
        		@file.errors.add(:file, :required.l)
        	end
        end
        
        @file.attributes = file_attribs
        
        @file.project = @active_project
        @file.is_visible = true
        @file.updated_by = @logged_user
        
        ProjectFile.transaction do
	        if @file.save
	          if file_data[:updated_file]
	          	if file_data[:version_file_change]
	          		@file.add_revision(file_data[:file], @file.project_file_revisions[0].revision_number+1, @logged_user, file_data[:revision_comment])
	          	else
	          		@file.update_revision(file_data[:file], @file.project_file_revisions[0], @logged_user, file_data[:revision_comment])
	          	end
	          	
	          	@file.filename = (file_data[:file].original_filename).sanitize_filename
	          end
	          
	          @file.tags = file_attribs[:tags]
	          
	          error_status(false, :success_edited_file)
	          redirect_back_or_default :controller => 'files'
	        end
        end
    end
  end
  
  def delete_file
    begin
      @file = @active_project.project_files.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      error_status(true, :invalid_file)
      redirect_back_or_default :controller => 'files'
      return
    end
    
    if not @file.can_be_deleted_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default :controller => 'files'
      return
    end
    
    @file.updated_by = @logged_user
    @file.destroy
    
    error_status(false, :success_deleted_file)
    redirect_back_or_default :controller => 'files'
  end
  
  def thumbnail
    begin
      file = ProjectFileRevision.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Not found', :status => 404
      return
    end
    
  	# Get thumbnail data
  	data = FileRepo.get_data(file.thumb_filename)
  	
  	if data.empty?
  		render :text => 'Not found', :status => 404
  		return
  	elsif data.class == Hash
  		redirect_to data[:url], :status => 302
  	end
  	
  	send_data data, :type => 'image/jpg', :disposition => 'inline'
  end
  
  def attach_to_object
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
    
    if not @attach_object.file_can_be_added_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default @attach_object.object_url
      return
    end
    
    case request.method
      when :post
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
      		does_exist = false
      		@attach_object.project_file.each do |check|
      			if check == existing_file
      				does_exist = true
      			end
      		end
      		
      		@attach_object.project_file << existing_file unless does_exist
      		
      		error_status(false, :success_added_file_to_object)
     		redirect_back_or_default @attach_object.object_url
     		return
      	end
      	
      	error_status(true, :error_adding_file_to_object)
        redirect_back_or_default @attach_object.object_url
      	return
    end
  end
  
  def detach_from_object
  	# params: manager, file_id, object_id
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
    
    if not @attach_object.file_can_be_added_by(@logged_user)
      error_status(true, :insufficient_permissions)
      redirect_back_or_default @attach_object.object_url
      return
    end

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

protected
  
  def accept_folder_name
    @folder = nil
    
    if params[:folder_name]
	    begin
	      @folder = @active_project.project_folders.find(:first, :conditions => ['name = ?', params[:folder_name]])
	    rescue ActiveRecord::RecordNotFound
	      error_status(true, :invalid_folder)
	      redirect_back_or_default :controller => 'files'
	      return false
	    end
	elsif params[:folder_id]
	    begin
	      @folder = @active_project.project_folders.find(params[:folder_id])
	    rescue ActiveRecord::RecordNotFound
	      error_status(true, :invalid_folder)
	      redirect_back_or_default :controller => 'files'
	      return false
	    end
    end
    
    return true
  end
  
end
