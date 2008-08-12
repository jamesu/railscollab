=begin
RailsCollab
-----------
Copyright (C) 2007 - 2008 James S Urquhart (jamesu at gmail.com)This program is free software; you can redistribute it and/ormodify it under the terms of the GNU General Public Licenseas published by the Free Software Foundation; either version 2of the License, or (at your option) any later version.This program is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied warranty ofMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See theGNU General Public License for more details.You should have received a copy of the GNU General Public Licensealong with this program; if not, write to the Free SoftwareFoundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
=end

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
	
	def site_name
		html_escape AppConfig.site_name
	end
	
	def product_signature
		:product_signature.l
	end
	
	def pagination_links(url, ids)
	 values = ids.collect do |id|
	   "<a href=\"#{url}page=#{id}\">#{id}</a>"
	 end.join ' | '
	 
	 "<div class=\"advancedPagination\"><span>#{:page.l}: </span><span>(#{values})</span></div>"
	end

	def checkbox_link(link, checked=false, hint=nil, attrs={})
    	icon_url = checked ? "/themes/#{AppConfig.site_theme}/images/icons/checked.gif" : "/themes/#{AppConfig.site_theme}/images/icons/not-checked.gif"
    	
    	link_to "<img src='#{icon_url}' alt='' />", link, attrs.merge({:method => :post, :class => 'checkboxLink', :title => ( hint.nil? ? '' : (html_escape hint) )})
	end
	
	def render_icon(filename, alt, attrs={})
		attr_values = attrs.keys.collect do |a|
			"#{a}='#{attrs[a]}'"
		end.join ' '
		
		"<img src='/themes/#{AppConfig.site_theme}/images/icons/#{filename}.gif' alt='#{alt}' #{attr_values}/>"
	end
	
	def action_list(actions)
		actions.collect do |action|
			if action[:cond]
				extras = {}
				extras[:confirm] = action[:confirm] if action.has_key? :confirm
				extras[:method] = action[:method] if action.has_key? :method
				extras[:onclick] = action[:onclick] if action.has_key? :onclick
				extras[:id] = action[:id] if action.has_key? :id
				
				link_to action[:name], action[:url], extras
			else
				nil
			end
		end.compact.join(' | ')
	end
	
	def tag_list(object)
		tags = Tag.list_by_object(object)
		
		if !tags.empty?
			tags.collect do |tag|
				tag_name = (h tag)
				"<a href=\"/project/#{object.project_id}/tags/#{tag_name}\">#{tag_name}</a>"
			end.join(', ')
		else
			"--"
		end
	end
	
	def country_code_select(object_name, method, extra_options={})
		countries = [TZInfo::Country.all.collect{|x|x.name},
		             TZInfo::Country.all_codes].transpose.sort
		select(object_name, method, countries, extra_options)
	end
	
	def format_size(value)
		kbs = value / 1024
		mbs = kbs / 1024
		
		if kbs > 0
			if mbs > 0
				"#{mbs}MB"
			else
				"#{kbs}KB"
			end
		else
			"#{value}B"
		end
	end
	
	def format_usertime(time, format, user=@logged_user)
		return '' if time.nil?
		time.strftime(format)
	end
	
	def yesno_toggle(object_name, method, options = {})
		radio_button(object_name, method, "true", options.merge({:id => "#{options[:id]}Yes"})) +
		" <label for=\"#{options[:id]}Yes\" class=\"#{options[:class]}\">#{:yesno_yes.l}</label> " +
		radio_button(object_name, method, "false", options.merge({:id => "#{options[:id]}No"})) +
		" <label for=\"#{options[:id]}No\" class=\"#{options[:class]}\">#{:yesno_no.l}</label>"
	end
	
	def yesno_toggle_tag(name, is_yes, options = {})
		radio_button_tag(name, "1", is_yes, options.merge({:id => "#{options[:id]}Yes"})) +
		" <label for=\"#{options[:id]}Yes\" class=\"#{options[:class]}\">#{:yesno_yes.l}</label> " +
		radio_button_tag(name, "0", !is_yes, options.merge({:id => "#{options[:id]}No"})) +
		" <label for=\"#{options[:id]}No\" class=\"#{options[:class]}\">#{:yesno_no.l}</label>"
	end
	
	def actions_for_user(user)
	   profile_updateable = user.profile_can_be_updated_by(@logged_user)
	   
	   [{:name => :update_profile.l, :url => "/account/edit_profile/#{user.id}", :cond => profile_updateable},
	    {:name => :change_password.l, :url => "/account/edit_password/#{user.id}", :cond => profile_updateable},
	    {:name => :update_avatar.l, :url => "/account/edit_avatar/#{user.id}", :cond => profile_updateable},
	    {:name => :permissions.l, :url => "/account/update_permissions/#{user.id}", :cond => user.permissions_can_be_updated_by(@logged_user)},
	    {:name => :delete.l, :url => "/user/delete/#{user.id}", :cond => user.can_be_deleted_by(@logged_user), :method => :post, :confirm => :confirm_user_delete.l}]
	end
	
	def actions_for_client(client)
	   [{:name => :add_user.l, :url => {:controller => 'user', :action => 'add', :company_id => client.id}, :cond => client.can_be_managed_by(@logged_user)},
	    {:name => :permissions.l, :url => {:controller => 'company', :action => 'update_permissions', :id => client.id}, :cond => client.can_be_managed_by(@logged_user)},
	    {:name => :edit.l, :url => {:controller => 'company', :action => 'edit_client', :id => client.id}, :cond => client.can_be_edited_by(@logged_user)},
	    {:name => :delete.l, :url => {:controller => 'company', :action => 'delete_client', :id => client.id}, :cond => client.can_be_deleted_by(@logged_user), :method => :post, :confirm => :delete_client_confirm.l}]
	end
	
	def actions_for_project(project)
	   [{:name => :edit.l, :url => {:controller => 'project', :action => 'edit', :active_project => project.id}, :cond => project.can_be_edited_by(@logged_user)},
	    {:name => :delete.l, :url => {:controller => 'project', :action => 'delete', :active_project => project.id}, :cond => project.can_be_deleted_by(@logged_user), :method => :post, :confirm => :project_confirm_delete.l}] 
	end
	
	def actions_for_form(form)
	   [{:name => :submit.l, :url => {:controller => 'form', :action => 'submit', :id => form.id}, :cond => form.can_be_submitted_by(@logged_user)},
	    {:name => :edit.l, :url => {:controller => 'form', :action => 'edit', :id => form.id}, :cond => form.can_be_edited_by(@logged_user)},
	    {:name => :delete.l, :url => {:controller => 'form', :action => 'delete', :id => form.id}, :cond => form.can_be_deleted_by(@logged_user), :method => :post, :confirm => :form_confirm_delete.l}]

	end
	
	def actions_for_milestone(milestone)
	   [{:name => :edit.l, :url => {:controller => 'milestone', :action => 'edit', :id => milestone.id}, :cond => milestone.can_be_edited_by(@logged_user)},
	    {:name => :delete.l, :url => {:controller => 'milestone', :action => 'delete', :id => milestone.id}, :cond => milestone.can_be_deleted_by(@logged_user), :method => :post, :confirm => :milestone_confirm_delete.l}]
	end
	
	def actions_for_task_list(task_list)
	   [{:name => :edit.l, :url => {:controller => 'task', :action => 'edit_list', :id => task_list.id}, :cond => task_list.can_be_changed_by(@logged_user)},
	    {:name => :delete.l, :url => {:controller => 'task', :action => 'delete_list', :id => task_list.id}, :cond => task_list.can_be_deleted_by(@logged_user), :method => :post, :confirm => :task_list_confirm_delete.l},
	    {:name => :reorder_tasks.l, :url => '#', :onclick => "task_view_sort(#{task_list.id}, #{task_list.project.id}); return false", :id => "sortTaskList#{task_list.id}", :cond => task_list.can_be_changed_by(@logged_user)}]
	end
	
	def actions_for_message(message)
	   [{:name => :edit.l, :url => {:controller => 'message', :action => 'edit', :id => message.id}, :cond => message.can_be_edited_by(@logged_user)},
	    {:name => :delete.l, :url => {:controller => 'message', :action => 'delete', :id => message.id}, :cond => message.can_be_deleted_by(@logged_user), :method => :post, :confirm => :message_confirm_delete.l}]
	end
	
	def actions_for_company(company)
	   [{:name => :edit.l, :url => {:controller => 'company', :action => 'edit', :id => @project.id, :company => company.id}, :cond => company.can_be_edited_by(@logged_user)},
	    {:name => :remove.l, :url => {:controller => 'project', :action => 'remove_company', :company => company.id}, :cond => company.can_be_removed_by(@logged_user), :method => :post, :confirm => :confirm_client_remove.l}]
	end
	
	def actions_for_comment(comment)
	   [{:name => :edit.l, :url => "/project/#{@active_project.id}/comment/edit/#{comment.id}", :cond => comment.can_be_edited_by(@logged_user)},
	    {:name => :delete.l, :url => "/project/#{@active_project.id}/comment/delete/#{comment.id}", :cond => comment.can_be_deleted_by(@logged_user), :method => :post, :confirm => :comment_delete_confirm.l}]
	end
	
	def actions_for_file(file, last_revision)
	   [{:name => :download_size.l_with_args(:size => format_size(last_revision.filesize)), :url => {:controller => 'files', :action => 'download_file', :id => file.id}, :cond => file.can_be_downloaded_by(@logged_user)},
	    {:name => :edit.l, :url => {:controller => 'files', :action => 'edit_file', :id => file.id}, :cond => file.can_be_edited_by(@logged_user)},
	    {:name => :delete.l, :url => {:controller => 'files', :action => 'delete_file', :id => file.id}, :cond => file.can_be_deleted_by(@logged_user), :method => :post, :confirm => :file_delete_confirmation.l}]
	end
	
	def actions_for_file_revision(file, revision)
	   [{:name => :download_size.l_with_args(:size => format_size(revision.filesize)), :url => {:controller => 'files', :action => 'download_file', :id => file.id, :revision => revision.revision_number}, :cond => file.can_be_downloaded_by(@logged_user)},
	    {:name => :edit.l, :url => {:controller => 'files', :action => 'edit_file', :id => file.id, :revision => revision.revision_number}, :cond => file.can_be_edited_by(@logged_user)}]
	end
	
	def actions_for_attached_files(attached_file, object)
	   [{:name => :details.l, :url => "/project/#{@active_project.id}/files/file_details/#{attached_file.id}", :cond => true},
	    {:name => :detatch.l, :url => "/project/#{@active_project.id}/files/detach_from_object/#{attached_file.id}?object_type=#{object.class.to_s}&object_id=#{object.id}", :cond => object.file_can_be_added_by(@logged_user), :method => :post, :confirm => :detatch_file_confirm.l}]
	end
	
	def actions_for_time(time)
	   [{:name => :details.l, :url => {:controller => 'time', :action => 'view', :id => time.id}, :cond => true},
	    {:name => :edit.l, :url => {:controller => 'time', :action => 'edit', :id => time.id}, :cond => time.can_be_edited_by(@logged_user)},
	    {:name => :delete.l, :url => {:controller => 'time', :action => 'delete', :id => time.id}, :cond => time.can_be_deleted_by(@logged_user), :method => :post, :confirm => :time_confirm_delete.l}]
	end
	
	def actions_for_time_short(time)
	   [{:name => :edit.l, :url => {:controller => 'time', :action => 'edit', :id => time.id}, :cond => time.can_be_edited_by(@logged_user)},
	    {:name => :delete.l, :url => {:controller => 'time', :action => 'delete', :id => time.id}, :cond => time.can_be_deleted_by(@logged_user), :method => :post, :confirm => :time_confirm_delete.l}]
	end
	
	def textilize(text)
	   if text.blank?
	       ""
	   else
	       textilized = RedCloth.new(text, [ :hard_breaks, :filter_html ])
	       textilized.hard_breaks = true if textilized.respond_to?("hard_breaks=")
	       textilized.to_html
	   end
	end
end
