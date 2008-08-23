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

# All-inclusive implementation of the BaseCamp API

class BasecampController < ApplicationController

  layout nil

  before_filter :ensure_content, :except => [:recent_items_rss, :recent_project_items_rss]
  before_filter :process_session
  #after_filter  :user_track
  
  # project/list
  def projects_list
  end
  
  def project_show
    begin
       @project = Project.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
	
	if not @project.can_be_seen_by(@logged_user)
      render :text => 'Error', :status => 404
      return
    end
  end
  
  # /contacts/companies
  def contacts_companies
  	if !@logged_user.member_of_owner?
  		render :text => 'Error', :status => 403
  		return
  	end
  	
  	@companies = [Company.owner]
  	if @active_project.nil?
  		@companies += Company.owner.clients
  	else
  		@companies += Company.owner.clients.reject { |company| !company.is_part_of(@active_project) }
  	end
  end
  
  # /contacts/company/#{company_id}
  def contacts_company
    begin
       @company = Company.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
	
	if not @company.can_be_seen_by(@logged_user)
      render :text => 'Error', :status => 404
      return
    end
  end
  
  # /contacts/people/#{company_id}
  # /projects/#{project_id}/contacts/people/#{company_id}
  def contacts_people
    begin
       @company = Company.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
	
	if not @company.can_be_seen_by(@logged_user)
      render :text => 'Error', :status => 404
      return
    end
    
    if @active_project.nil?
    	@people = @company.users
    else
    	@people = @company.users.reject { |user| !user.member_of(@active_project) }
    end
  end
  
  # /contacts/person/#{person_id}
  def contacts_person
    begin
      @user = User.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
	
	if not @user.can_be_viewed_by(@logged_user)
      render :text => 'Error', :status => 404
      return
    end
  end
  
  # /projects/#{project-id}/attachment_categories
  def projects_attachment_categories
	@folders = @active_project.project_folders
  end
  
  # /projects/#{project-id}/post_categories
  def projects_post_categories
	@categories = @active_project.project_message_categories
  end
  
  # /msg/comment/#{comment_id}
  def msg_comment
    begin
       @comment = Comment.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
	
	if not @comment.can_be_seen_by(@logged_user)
      render :text => 'Error', :status => 404
      return
    end
  end
  
  # /msg/comments/#{message_id}
  def msg_comments
    begin
       @message = ProjectMessage.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
	
	if not @message.can_be_seen_by(@logged_user)
      render :text => 'Error', :status => 404
      return
    end
	
	@comments = @logged_user.member_of_owner? ? @message.comments : @message.comments.public
  end
  
  # /msg/create_comment
  def msg_create_comment
  	comment_attribs = @request_fields[:comment]
  	    
    begin
      message = ProjectMessage.find(comment_attribs[:post_id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
	
	if not message.comment_can_be_added_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    @comment = Comment.new(:text => comment_attribs[:body])
    @comment.rel_object = message
    @comment.created_by = @logged_user
    @comment.author_homepage = request.remote_ip
    
    if @comment.save
    	# Notify everyone
    	message.send_comment_notifications(@comment)
    	
    	render :template => 'basecamp/msg_comment', :status => 201
    else
    	render :text => 'Error', :status => 500
    	return
    end
  end
  
  # /projects/#{project_id}/msg/create
  def projects_msg_create
    if not ProjectMessage.can_be_created_by(@logged_user, @active_project)
      render :text => 'Error', :status => 403
      return
    end
    
    post_attribs = @request_fields[:post]
    
    @message = ProjectMessage.new(
    		:category_id => post_attribs[:category_id],
    		:title => post_attribs[:title],
    		:text => post_attribs[:body],
    		:additional_text => post_attribs[:extended_body],
    		:is_private => post_attribs[:private]
    )
    
    @message.is_private ||= false # Fix for dodgy widgets
    @message.project = @active_project
    @message.created_by = @logged_user
    
    if @message.save
    	# Notify specified users
    	if !@request_fields[:notify].nil?
    		valid_users = @request_fields[:notify].collect do |user_id|
    			real_id = user_id.to_i
    			
    			if ProjectUser.find(:all, :conditions => ["user_id = ? AND project_id = ?", real_id, @active_project.id]).length > 0
    				real_id
    			else
    				nil
    			end
    		end
    	
    		User.find(:all, :conditions => "id IN (#{valid_users.compact.join(',')})").each do |user|
    			@message.send_notification(user)
    		end
    	end
    	
    	# Handle file attachments
    	if !@request_fields[:attachments].nil?
    		# TODO
    	end
    	
    	render :template => 'basecamp/msg_update', :status => 201
    else
    	render :text => 'Error', :status => 500
    	return
    end
  end
  
  # /msg/delete_comment/#{comment_id}
  def msg_delete_comment
    begin
       @comment = Comment.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
	
	if not @comment.can_be_deleted_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    @comment.updated_by = @logged_user
    @comment.destroy
    
    render :template => 'basecamp/msg_comment'
  end
  
  # /msg/delete/#{message_id}
  def msg_delete
    begin
       @message = ProjectMessage.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
	
	if not @message.can_be_deleted_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    @message.updated_by = @logged_user
    @message.destroy

    render :template => 'basecamp/msg_update'
  end
  
  # /msg/get/#{message_ids}
  def msg_get
  	message_ids = params[:ids].split(',').collect { |id| id.to_i }.uniq.join(',')
  	
  	@messages = ProjectMessage.find(:all, :conditions => "id IN (#{message_ids})").reject do |message|
  		!message.can_be_seen_by(@logged_user)
  	end
  end
  
  # /projects/#{project_id}/msg/archive
  # /projects/#{project_id}/msg/cat/#{category_id}/archive
  def projects_msg_archive
  	if !@request_fields.nil? and @request_fields.has_key?(:project_id)
    	begin
  			project = Project.find(@request_fields[:project_id])
  		rescue ActiveRecord::RecordNotFound
  			render :text => 'Error', :status => 404
  			return
  		end
  	else
  		project = @active_project
  	end
  	
  	category_id = params[:cat_id]
  	category_id ||= @request_fields[:category_id] unless @request_fields.nil?
  	
  	# Base filter based on is_private and optional category_id
  	msg_conditions =  @logged_user.member_of_owner? ?
  	                  ['project_id = ?', project.id] :
  	                  ['project_id = ? AND is_private = ?', project.id, false]
  	unless category_id.nil?
  		msg_conditions[0] += 'AND category_id = ?'
  		msg_conditions.push(category_id.to_i)
  	end
  	
  	@messages = ProjectMessage.find(:all, :conditions => msg_conditions)
  end
  
  # /msg/update_comment
  def msg_update_comment   
    begin
       @comment = Comment.find(@request_fields[:comment_id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
    
    if not @comment.can_be_edited_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    comment_attribs = @request_fields[:comment]
    
    @comment.text = comment_attribs[:body]
    @comment.updated_by = @logged_user
    
    unless @comment.save
    	render :text => 'Error', :status => 500
    	return
    end
    
    render :template => 'basecamp/msg_comment'
  end
  
  # /msg/update/#{message_id}
  def msg_update
    begin
       @message = ProjectMessage.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
  	
    if not @message.can_be_edited_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    post_attribs = @request_fields[:post]
    
    @message.attributes = {
    		:category_id => post_attribs[:category_id],
    		:title => post_attribs[:title],
    		:text => post_attribs[:body],
    		:additional_text => post_attribs[:extended_body],
    		:is_private => post_attribs[:private]
    }
    
    @message.is_private ||= false # Fix for dodgy widgets
    @message.updated_by = @logged_user
    
    if @message.save
    	# Notify specified users
    	# TODO
    	
    	# Handle file attachments
    	if !@request_fields[:attachments].nil?
    		# TODO
    	end
    else
    	render :text => 'Error', :status => 500
    	return
    end
  end
  
  # /todos/complete_item/#{id}
  def todos_complete_item
    begin
      @task = ProjectTask.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
    
    if not @task.can_be_changed_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    if @task.completed_by.nil?
      @task.completed_on = Time.now.utc
      @task.completed_by = @logged_user
      
      unless @task.save
      	render :text => 'Error', :status => 500
      	return
      end
    end
    
    render :template => 'basecamp/todos_update_item'
  end
  
  # /todos/create_item/#{list_id}
  def todos_create_item
    begin
      task_list = ProjectTaskList.find(params[:list_id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
    
    if not ProjectTaskList.can_be_created_by(@logged_user, task_list)
      render :text => 'Error', :status => 403
      return
    end
    
    @task = ProjectTask.new(
    		:text => @request_fields[:content],
    		:assigned_to_id => @request_fields[:responsible_party]
    )
    
    # TODO: notify?
    
    #@task.project = @active_project
    @task.task_list = task_list
    @task.created_by = @logged_user
    
    if @task.save
    	render :template => 'basecamp/todos_update_item', :status => 201
    else
    	render :text => 'Error', :status => 500
    end
  end
  
  # /projects/#{project_id}/todos/create_list
  def projects_todos_create_list
    if not ProjectTaskList.can_be_created_by(@logged_user, @active_project)
      render :text => 'Error', :status => 403
      return
    end
    
    @task_list = ProjectTaskList.new(
    		:name => @request_fields[:name],
    		:description => @request_fields[:description],
    		:milestone_id => @request_fields[:milestone_id],
    		:is_private => @request_fields[:private]
    )
    
    # TODO: tracked, use-template, template-id
    # TODO: notify?
    
    @task_list.project = @active_project
    @task_list.created_by = @logged_user
    
    if @task_list.save
    	render :template => 'basecamp/todos_list', :status => 201
    else
    	render :text => 'Error', :status => 500
    end
  end
  
  # /todos/delete_item/#{id}
  def todos_delete_item
    begin
       @task = ProjectTask.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
	
	if not @task.can_be_deleted_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    @task.updated_by = @logged_user
    @task.destroy

    render :template => 'basecamp/todos_update_item'
  end
  
  # /todos/delete_list/#{id}
  def todos_delete_list
    begin
       @task_list = ProjectTaskList.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
	
	if not @task_list.can_be_deleted_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    @task_list.updated_by = @logged_user
    @task_list.destroy

    render :template => 'basecamp/todos_list'
  end
  
  # /todos/list/#{id}
  def todos_list
    begin
       @task_list = ProjectTaskList.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
  	
    if not @task_list.can_be_seen_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
  end
  
  # /projects/#{project_id}/todos/lists
  def projects_todos_lists
  	# Allow for constraints
  	if !@request_fields.nil?
  		if @request_fields.has_key?(:complete)
  			@task_lists = @request_fields[:complete] ? @active_project.project_task_lists.completed(@logged_user.member_of_owner?) : 
  			                                           @active_project.project_task_lists.open(@logged_user.member_of_owner?)
  			return
  		end
  	end
  	
  	# Otherwise display everything
  	@task_lists = @active_project.project_task_lists
  	
  	# Filter out private
  	unless @logged_user.member_of_owner?
  		@task_lists = @task_lists.reject { |list| list.is_private? }
  	end
  end
  
  # /todos/move_item/#{id}
  def todos_move_item
    begin
      @task = ProjectTask.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
    
    @task_list = @task.project_task_list
    
    if not @task_list.can_be_changed_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    # Maps in the range 1...num_tasks
    num_tasks = @task_list.project_tasks.length
    target_idx = (@request_fields[:to].to_i-1) %  @task_list.project_tasks.length
    
    # Increment and set where applicable
  	@task_list.tasks.each do |task|
  		next if task.id == @task.id
  		
  		if task.id == target_idx
  			@task.id = target_idx
  			@task.save!
  		end
  		
  		task.order = (task.order+1) % @task_list.project_tasks.length
  		task.save!
  	end
  	
  	render :template => 'basecamp/todos_update_item'
  end
  
  # /todos/move_list/#{id}
  def todos_move_list
    begin
      @task_list = ProjectTaskList.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
    
    if not @task_list.can_be_changed_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    # Maps in the range 1...num_tasks
    @task_list.priority = @request_fields[:to]
    unless @task_list.save
      	render :text => 'Error', :status => 500
      	return
    end
  	
  	render :template => 'basecamp/todos_list'
  end
  
  # /todos/uncomplete_item/#{id}
  def todos_uncomplete_item
    begin
      @task = ProjectTask.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
    
    if not @task.can_be_changed_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    if !@task.completed_by.nil?
      @task.completed_on = 0
      @task.completed_by = nil
      
      unless @task.save
      	render :text => 'Error', :status => 500
      	return
      end
    end
    
    render :template => 'basecamp/todos_update_item'
  end
  
  # /todos/update_item/#{id}
  def todos_update_item
    begin
      @task = ProjectTask.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
    
    if not @task.can_be_changed_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    task_attribs = @request_fields[:todo_item]
    
    @task.text = @request_fields[:item][:content]
    @task.assigned_to_id = @request_fields[:responsible_party]
    @task.updated_by = @logged_user
    
    unless @task.save
      render :text => 'Error', :status => 500
      return
    end
    
    render :template => 'basecamp/todos_update_item'
  end
  
  # /todos/update_list/#{id}
  def todos_update_list
    begin
      @task_list = ProjectTaskList.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
    
    if not @task_list.can_be_changed_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    task_list_attribs = @request_fields[:list]
    
    @task_list.attribues = {
    		:name => task_list_attribs[:name],
    		:description => task_list_attribs[:description],
    		:milestone_id => task_list_attribs[:milestone_id],
    		:is_private => task_list_attribs[:private]
    }
    
    # TODO: tracked
    @task_list.updated_by = @logged_user
        
    unless @task_list.save
      render :text => 'Error', :status => 500
      return
    end
    
    render :template => 'basecamp/todos_list'
  end
  
  # /milestones/complete/#{id}
  def milestones_complete
    begin
      @milestone = ProjectMilestone.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
    
    if not @milestone.status_can_be_changed_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    if @milestone.completed_by.nil?
      @milestone.completed_on = Time.now.utc
      @milestone.completed_by = @logged_user
      
      unless @milestone.save
      	render :text => 'Error', :status => 500
      	return
      end
    end
    
    render :template => 'basecamp/milestones_update'
  end
  
  # /projects/#{project_id}/milestones/create
  def projects_milestones_create
    if not ProjectMilestone.can_be_created_by(@logged_user, @active_project)
      render :text => 'Error', :status => 403
      return
    end
    
    milestone_attribs = @request_fields[:milestone]
    
    @milestone = ProjectMilestone.new(
    		:name => milestone_attribs[:title],
    		:due_date => Date.parse(milestone_attribs[:deadline]),
    		:assigned_to_id => milestone_attribs[:responsible_party]
    )
    
    # TODO: notify?
        
    @milestone.project = @active_project
    @milestone.created_by = @logged_user
    
    if @milestone.save
    	render :template => 'basecamp/milestones_update', :status => 201
    else
    	render :text => 'Error', :status => 500
    end
  end
  
  # /milestones/delete/#{id}
  def milestones_delete
    begin
       @milestone = ProjectMilestone.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
	
	if not @milestone.can_be_deleted_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    @milestone.updated_by = @logged_user
    @milestone.destroy
    
    render :template => 'basecamp/milestones_update'
  end
  
  # /projects/#{project_id}/milestones/list
  def projects_milestones_list
  	include_private = @logged_user.member_of_owner?
  	
  	# Allow for constraints
  	if !@request_fields.nil?
  		if @request_fields.has_key?(:find)
  			case @request_fields[:find]
  				when 'late'
  					@milestones = @active_project.project_milestones.late(include_private)
  					return
  				when 'completed'
  					@milestones = @active_project.project_milestones.completed(include_private)
  					return
  				when 'upcoming'
  					@milestones = @active_project.project_milestones.upcoming(include_private)
  					return
  			end
  		end
  	end
  	
  	# Otherwise display everything
  	@milestones = include_private ? @active_project.project_milestones : @active_project.project_milestones.public
  end
  
  # /milestones/uncomplete/#{id}
  def milestones_uncomplete
    begin
      @milestone = ProjectTask.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
    
    if not @milestone.status_can_be_changed_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    if !@milestone.completed_by.nil?
      @milestone.completed_on = 0
      @milestone.completed_by = nil
      
      unless @milestone.save
      	render :text => 'Error', :status => 500
      	return
      end
    end
    
    render :template => 'basecamp/milestones_update'
  end
  
  # /milestones/update/#{id}
  def milestones_update
    begin
      @milestone = ProjectTaskList.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
    
    if not @milestone.can_be_edited_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    milestone_attribs = @request_fields[:milestone]
    
    @milestone.attribues = {
    		:name => milestone_attribs[:title],
    		:due_date => Date.parse(milestone_attribs[:deadline]),
    		:assigned_to_id => milestone_attribs[:responsible_party]
    }
    
    # TODO: notify, move-upcoming-milestones, move-upcoming-milestones-off-weekends
    @milestone.updated_by = @logged_user
        
    unless @milestone.save
      render :text => 'Error', :status => 500
      return
    end
  end
  
  # /time/save_entry
  def time_save_entry
    time_attribs = @request_fields[:entry]
    project = Project.find(time_attribs[:project_id])
    
    if not ProjectTime.can_be_created_by(@logged_user, project)
      render :text => 'Error', :status => 403
      return
    end
    
    @time = ProjectTime.new(
    		:name => time_attribs.has_key?(:todo_item_id) ? 
    		         ProjectTime.find(time_attribs[:todo_item_id]).object_name : 
    		         time_attribs[:description],
    		:done_date => Date.parse(time_attribs[:date]),
    		:hours => time_attribs[:hours],
    		:assigned_to_id => time_attribs[:person_id],
    		:open_task_id => time_attribs[:todo_item_id]
    )
    
    # TODO: notify?
        
    @time.project = project
    @time.created_by = @logged_user
    
    if @time.save
    	render :template => 'basecamp/time_save_entry', :status => 201
    else
    	render :text => 'Error', :status => 500
    end
  end
  
  # /projects/#{project_id}/time/delete_entry/#{id}
  def projects_time_delete_entry
    begin
       @time = ProjectTime.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
	
	if not @time.can_be_deleted_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    @time.updated_by = @logged_user
    @time.destroy
    
    render :template => 'basecamp/time_save_entry'
  end
  
  # /time/report/#{person-id}/#{from}/#{to}/#{filter}
  def time_report
  	if params[:id].nil? || params[:id] == '0'
  		user_filter = ""
  	else
    	begin
    	   user = User.find(params[:id])
    	rescue ActiveRecord::RecordNotFound
      		render :text => 'Error', :status => 404
      		return
    	end
	
		if not user.can_be_viewed_by(@logged_user)
      		render :text => 'Error', :status => 404
      		return
    	end
    	
    	user_filter = "created_by = #{user.id} AND"
    end
    
    # Date range
  	start_time = params[:from] == '0' ? ( Time.now.utc - 7776000 ) : Time.parse(params[:from])
  	end_time = params[:to] == '0' ? Time.now.utc : Time.parse(params[:to])
  	
  	# Base filter based on is_private
  	time_conditions = @logged_user.member_of_owner? ?
  	                  ["#{user_filter} done_date >= ? AND done_date <= ?", start_time, end_time] :
  	                  ["#{user_filter} is_private = ? AND done_date >= ? AND done_date <= ?", false, start_time, end_time]
  	
  	# Now we can grab the times!
  	filter = params[:filter]
  	unless filter.nil?
  		filter_id = filter[1...filter.length]
  		
  		if filter[0] == 99 #'c'
  			# Filter by company
  			begin
  				company = Company.find(filter_id)
  			rescue ActiveRecord::RecordNotFound
  				render :text => 'Error', :status => 404
  				return
  			end
  			
  			projects = company.projects.collect { |project| project.id }.join(',')
  			
  			time_conditions[0] += " AND project_id IN (#{projects})"
  			@times = ProjectTime.find(:all, :conditions => time_conditions)
  		elsif filter[0] == 112 #'p'
  			# Filter by project
  			begin
  				project = Project.find(filter_id)
  			rescue ActiveRecord::RecordNotFound
  				render :text => 'Error', :status => 404
  				return
  			end
  			
  			time_conditions[0] += " AND project_id = #{project.id}"
  			#render :text => time_conditions[0]
  			#return
  			@times = ProjectTime.find(:all, :conditions => time_conditions)
  		end
  	end
  	
  	# Just select everything
  	@times = ProjectTime.find(:all, :conditions => time_conditions)
  end
  
  # /time/save_entry/#{id}
  def time_update_entry
    time_attribs = @request_fields[:entry]
    project = Project.find(time_attribs[:project_id])
    
  	# First check to see if we can add to the destination project
    if not ProjectTime.can_be_created_by(@logged_user, project)
      render :text => 'Error', :status => 403
      return
    end
    
    # Check to see if we can modify this time
    begin
      @time = ProjectTime.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render :text => 'Error', :status => 404
      return
    end
    
    if not @time.can_be_edited_by(@logged_user)
      render :text => 'Error', :status => 403
      return
    end
    
    # Apply modifications
    
    @time.attribues = {
    		:name => time_attribs.has_key?(:todo_item_id) ? 
    		         ProjectTime.find(time_attribs[:todo_item_id]).object_name : 
    		         time_attribs[:description],
    		:done_date => Date.parse(time_attribs[:date]),
    		:hours => time_attribs[:hours],
    		:assigned_to_id => time_attribs[:person_id],
    		:open_task_id => time_attribs[:todo_item_id]
    }
    
    @time.updated_by = @logged_user
        
    unless @time.save
      render :text => 'Error', :status => 500
      return
    end
    
  	render :template => 'basecamp/time_save_entry'
  end
  
  # RSS feeds
  
  # /feed/recent_items_rss
  def recent_items_rss
  	@activity_log = ApplicationLog.logs_for(@logged_user.projects, @logged_user.member_of_owner?, @logged_user.is_admin, 50)
 	@activity_url = AppConfig.site_url + '/feed/recent_items_rss'
  
  	render :text => '404 Not found', :status => 404 unless @activity_log.length > 0
  	render :template => 'feed/recent_activities'
  end
  
  # /projects/#{id}/feed/recent_items_rss
  def recent_project_items_rss
  	@activity_log = ApplicationLog.logs_for(@active_project, @logged_user.member_of_owner?, @logged_user.is_admin, 50)
 	@activity_url = AppConfig.site_url + "/projects/#{@active_project.id}/feed/recent_items_rss"
  
  	render :text => '404 Not found', :status => 404 unless @activity_log.length > 0
  	render :template => 'feed/recent_activities'
  end
  
private

  def ensure_content
  	if request.accepts.first == Mime::XML
  		@request_fields = params[:request]
  		
  		true
  	else
  		render :text => 'Not found', :status => 404
  		false
  	end
  end
  
end
