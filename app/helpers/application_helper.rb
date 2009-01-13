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

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def site_name
    html_escape AppConfig.site_name
  end

  def product_signature
    :product_signature.l
  end

  def pagination_links(url, ids)
    values = ids.collect{ |id| "<a href=\"#{url}page=#{id}\">#{id}</a>" }.join(' | ')

    "<div class=\"advancedPagination\"><span>#{:page.l}: </span><span>(#{values})</span></div>"
  end

  def checkbox_link(link, checked=false, hint=nil, attrs={})
    icon_url = checked ? "/themes/#{AppConfig.site_theme}/images/icons/checked.gif" : "/themes/#{AppConfig.site_theme}/images/icons/not-checked.gif"
    
    method = attrs[:method] || :post
    link_to "<img src='#{icon_url}' alt='' />", link, attrs.merge({:method => method, :class => 'checkboxLink', :title => ( hint.nil? ? '' : (html_escape hint) )})
  end

  def render_icon(filename, alt, attrs={})
    attr_values = attrs.keys.collect{ |a| "#{a}='#{attrs[a]}'" }.join(' ')

    "<img src='/themes/#{AppConfig.site_theme}/images/icons/#{filename}.gif' alt='#{alt}' #{attr_values}/>"
  end

  def action_list(actions)
    actions.collect do |action|
      if action[:cond]
        extras = {}
        extras[:confirm] = action[:confirm] if action.has_key? :confirm
        extras[:method]  = action[:method]  if action.has_key? :method
        extras[:onclick] = action[:onclick] if action.has_key? :onclick
        extras[:id]      = action[:id]      if action.has_key? :id
        extras[:class] = action[:class] if action.has_key? :class

        link_to action[:name], action[:url], extras
      else
        nil
      end
    end.compact.join(' | ')
  end

  def tag_list(object)
    tags = Tag.list_by_object(object)
    return '--' if tags.empty?

    tags.collect do |tag|
      tag_name = (h tag)
      "<a href=\"/project/#{object.project_id}/tags/#{tag_name}\">#{tag_name}</a>"
    end.join(', ')
  end

  def format_size(value)
    kbs = value / 1024
    mbs = kbs / 1024

    return "#{value}B" if value < 1.kilobytes
    return "#{kbs}KB"  if value < 1.megabytes
    "#{mbs}MB"
  end

  def format_usertime(time, format, user=@logged_user)
    return '' if time.nil?
    time.strftime(format)
  end

  def yesno_toggle(object_name, method, options = {})
    radio_button(object_name, method, "true", options.merge({:id => "#{options[:id]}Yes"}))    +
    " <label for=\"#{options[:id]}Yes\" class=\"#{options[:class]}\">#{:yesno_yes.l}</label> " +
    radio_button(object_name, method, "false", options.merge({:id => "#{options[:id]}No"}))    +
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
	   
	   actions = [{:name => :edit.l, :url => "/user/edit/#{user.id}", :cond => profile_updateable}]
	   
	   if @active_project.nil?
	     actions += [
	       {:name => :delete.l, :url => "/user/delete/#{user.id}", :cond => user.can_be_deleted_by(@logged_user), :method => :post, :confirm => :confirm_user_delete.l},
	       {:name => :permissions.l, :url => "/account/update_permissions/#{user.id}", :cond => user.permissions_can_be_updated_by(@logged_user)}]
	   else
	     actions << {:name => :remove.l, :url => "/project/#{@active_project.id}/remove_user/#{user.id}", :cond => user.can_be_deleted_by(@logged_user), :method => :post, :confirm => :confirm_user_remove.l}
	   end
	   
	   actions
	end

  def actions_for_project(project)
    [{:name => :edit.l,   :url => {:controller => 'project', :action => 'edit',   :active_project => project.id}, :cond => project.can_be_edited_by(@logged_user)},
     {:name => :delete.l, :url => {:controller => 'project', :action => 'delete', :active_project => project.id}, :cond => project.can_be_deleted_by(@logged_user), :method => :post, :confirm => :project_confirm_delete.l}]
  end

  def actions_for_milestone(milestone)
    [{:name => :edit.l,   :url => {:controller => 'milestone', :action => 'edit',   :id => milestone.id}, :cond => milestone.can_be_edited_by(@logged_user)},
     {:name => :delete.l, :url => {:controller => 'milestone', :action => 'delete', :id => milestone.id}, :cond => milestone.can_be_deleted_by(@logged_user), :method => :post, :confirm => :milestone_confirm_delete.l}]
  end

  def actions_for_task_list(task_list)
    [{:name => :edit.l,          :url => edit_task_list_path(:id => task_list.id), :cond => task_list.can_be_changed_by(@logged_user)},
     {:name => :delete.l,        :url => task_list_path(:id => task_list.id), :cond => task_list.can_be_deleted_by(@logged_user), :method => :delete, :confirm => :task_list_confirm_delete.l},
     {:name => :reorder_tasks.l, :url => '#', :class => 'doSortTaskList', :cond => task_list.can_be_changed_by(@logged_user)}]
  end

  def actions_for_message(message)
    [{:name => :edit.l,   :url => {:controller => 'message', :action => 'edit',   :id => message.id}, :cond => message.can_be_edited_by(@logged_user)},
     {:name => :delete.l, :url => {:controller => 'message', :action => 'delete', :id => message.id}, :cond => message.can_be_deleted_by(@logged_user), :method => :post, :confirm => :message_confirm_delete.l}]
  end

  def actions_for_company(company)
    actions = [
      {:name => :add_user.l, :url => "/user/add?company_id=#{company.id}", :cond => (@active_project.nil? and User.can_be_created_by(@logged_user))}, 
      {:name => :edit.l,   :url => {:controller => 'company', :action => 'edit', :id => company.id}, :cond => company.can_be_edited_by(@logged_user)}]
    
    unless @active_project.nil?
      actions << {:name => :remove.l, :url => {:controller => 'project', :action => 'remove_company', :id => company.id}, :cond => company.can_be_removed_by(@logged_user), :method => :post, :confirm => :confirm_client_remove.l}
    else
      actions << {:name => :permissions.l, :url => {:controller => 'company', :action => 'update_permissions', :id => company.id}, :cond => company.can_be_managed_by(@logged_user)}
    end
    
    actions
  end

  def actions_for_comment(comment)
    [{:name => :edit.l,   :url => "/project/#{@active_project.id}/comment/edit/#{comment.id}",   :cond => comment.can_be_edited_by(@logged_user)},
     {:name => :delete.l, :url => "/project/#{@active_project.id}/comment/delete/#{comment.id}", :cond => comment.can_be_deleted_by(@logged_user), :method => :post, :confirm => :comment_delete_confirm.l}]
  end

  def actions_for_file(file, last_revision)
    [{:name => :details_size.l_with_args(:size => format_size(last_revision.filesize)), :url => {:controller => 'files', :action => 'file_details', :id => file.id}, :cond => file.can_be_downloaded_by(@logged_user)},
     {:name => :edit.l,   :url => {:controller => 'files', :action => 'edit_file',   :id => file.id}, :cond => file.can_be_edited_by(@logged_user)},
     {:name => :delete.l, :url => {:controller => 'files', :action => 'delete_file', :id => file.id}, :cond => file.can_be_deleted_by(@logged_user), :method => :post, :confirm => :file_delete_confirmation.l}]
  end

  def actions_for_file_revision(file, revision)
    [{:name => :download_size.l_with_args(:size => format_size(revision.filesize)), :url => {:controller => 'files', :action => 'download_file', :id => file.id, :revision => revision.revision_number}, :cond => file.can_be_downloaded_by(@logged_user)},
     {:name => :edit.l,                                                             :url => {:controller => 'files', :action => 'edit_file',     :id => file.id, :revision => revision.revision_number}, :cond => file.can_be_edited_by(@logged_user)}]
  end

  def actions_for_attached_files(attached_file, object)
    [{:name => :details.l, :url => "/project/#{@active_project.id}/files/file_details/#{attached_file.id}", :cond => true},
     {:name => :detatch.l, :url => "/project/#{@active_project.id}/files/detach_from_object/#{attached_file.id}?object_type=#{object.class.to_s}&object_id=#{object.id}", :cond => object.file_can_be_added_by(@logged_user), :method => :post, :confirm => :detatch_file_confirm.l}]
  end

  def actions_for_time(time)
    [{:name => :details.l, :url => {:controller => 'time', :action => 'view',   :id => time.id}, :cond => true},
     {:name => :edit.l,    :url => {:controller => 'time', :action => 'edit',   :id => time.id}, :cond => time.can_be_edited_by(@logged_user)},
     {:name => :delete.l,  :url => {:controller => 'time', :action => 'delete', :id => time.id}, :cond => time.can_be_deleted_by(@logged_user), :method => :post, :confirm => :time_confirm_delete.l}]
  end

  def actions_for_time_short(time)
    [{:name => :edit.l,   :url => {:controller => 'time', :action => 'edit',   :id => time.id}, :cond => time.can_be_edited_by(@logged_user)},
     {:name => :delete.l, :url => {:controller => 'time', :action => 'delete', :id => time.id}, :cond => time.can_be_deleted_by(@logged_user), :method => :post, :confirm => :time_confirm_delete.l}]
  end
  
  def cal_table(in_rows, tableclass)
    rows = in_rows.map do |row|
      columns = row.map do |column|
        case column[0]
          when :mday
            "<td>#{column[1]}</td>"
          when :bday
            "<td class=\"blank\"></td>"
          when :th
            "<th>#{column[1]}</th>"
          when :thm
            "<th class=\"month\" rowspan=\"#{column[2]}\">#{column[1]}</th>"
        end
      end
      "<tr>#{columns}</tr>"
    end
    "<table class=\"#{tableclass}\"><tbody>#{rows}</tbody></table>"
  end
  
  def calendar_days
    ['', :wday_1.l, :wday_2.l, :wday_3.l, :wday_4.l, :wday_5.l, :wday_6.l, :wday_7.l]
  end
  
  def calendar_wdays
    ['', :wday_7.l, :wday_1.l, :wday_2.l, :wday_3.l, :wday_4.l, :wday_5.l, :wday_6.l]
  end
  
  def months_calendar(start_date, end_date, tableclass, days=calendar_days, offset=0, merge_month=false)
    # Day header
    rows = [days.map { |content| [:th, content]}]
    
    # Iterate until final month
    cur_date = start_date
    final_date = Date.civil(end_date.year, end_date.month, 1)
    while cur_date < final_date
      days_in_month = Date.civil(cur_date.year, cur_date.month, -1).day
      start_of_month = (Date.civil(cur_date.year, cur_date.month, 1).cwday + offset) % 8
      
      # Month row
      month_row = [:thm, "month_#{cur_date.month}".to_sym.l, 0]
      day_rows = 1
      rows << [month_row]
      
      # Blank days
      cur_row = (1...start_of_month).map { |d| [:bday] }
      
      # Month days
      wday_count = start_of_month
      (1..days_in_month).each do |d|
        cur_row << [:mday, yield(Date.civil(cur_date.year, cur_date.month, d))]
        
        wday_count += 1
        if wday_count % 8 == 0
          rows << cur_row
          day_rows += 1
          wday_count = 1
          cur_row = []
        end
      end
      
      # Remaining blank days
      unless wday_count == 1
        if merge_month
          # Add the days of the next month
          (8-wday_count).times { cur_row << [:bday, yield(Date.civil(cur_date.year, cur_date.month, d))] }
        else
          # Just bank out the rest
          (8-wday_count).times { cur_row << [:bday] }
        end
        rows << cur_row
        day_rows += 1
      end
      
      month_row[2] = day_rows
      
      cur_date += 1.month
    end
    
    cal_table(rows, tableclass)
  end

  def days_calendar(start_date, end_date, tableclass)
    # Day header
    start_day = start_date.cwday
    days = calendar_days
    rows = [(days[start_day..7] + days[1...start_day]).map { |content| [:th, content] }]
    cur_row = []
    
    # Iterate until final day
    wday_count = 1
    cur_date = start_date
    while (cur_date < end_date)
      cur_row << [:mday, yield(cur_date)]
      
      wday_count += 1
      if wday_count % 8 == 0
        rows << cur_row
        wday_count = 1
        cur_row = []
      end
            
      last_day = cur_date.day
      cur_date += 1
    end
    
    # Finish off the rest of the week days
    unless wday_count == 1
      (8-wday_count).times { cur_date += 1; cur_row << [:mday, yield(cur_date)] }
      rows << cur_row
    end
    
    cal_table(rows, tableclass)
  end
    
  def calendar_block(content, items, classname, force=false)
    return content if items.nil? and !force
    
    list = unless items.nil?
      mitems = items.collect { |item|
        "<li><a href=\"#{item.object_url}\">#{item.object_name}</a></li>"
      }.join
      "<ul>#{mitems}</ul>"
    else
      ''
    end
    
    "<div class=\"#{classname}\">#{content} #{list}</div>"
  end

  def textilize(text)
    return '' if text.blank?

    textilized = RedCloth.new(text, [ :hard_breaks, :filter_html ])
    textilized.hard_breaks = true if textilized.respond_to?('hard_breaks=')
    textilized.to_html
  end
end
