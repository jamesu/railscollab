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

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def site_name
    html_escape Rails.configuration.site_name
  end

  def product_signature
    I18n.t('product_signature').html_safe
  end

  def pagination_links(url, ids)
    values = ids.collect{ |id| "<a href=\"#{url}page=#{id}\">#{id}</a>" }.join(' | ')

    "<div class=\"advancedPagination\"><span>#{I18n.t('page')}: </span><span>(#{values})</span></div>".html_safe
  end
  
  def icon_url(filename)
    "/assets/icons/#{filename}.gif"
  end

  def checkbox_link(link, checked=false, hint=nil, attrs={})
    icon_url = checked ? "/assets/icons/checked.gif" : "/assets/icons/not-checked.gif"
    
    method = attrs[:method] || :post
    link_to "<img src='#{icon_url}' alt='' />".html_safe, link, attrs.merge({:method => method, :class => 'checkboxLink', :title => ( hint.nil? ? '' : (html_escape hint) )})
  end

  def render_icon(filename, alt, attrs={})
    attr_values = attrs.keys.collect{ |a| "#{a}='#{attrs[a]}'" }.join(' ')

    "<img src='/assets/icons/#{filename}.gif' alt='#{alt}' #{attr_values}/>".html_safe
  end
  
  def loading_spinner
    image_tag 'spinner.gif', {:class => 'loadingSpinner'}
  end

  def action_list(actions)
    actions.collect do |action|
      if action[:cond]
        extras = {}

        extras[:confirm] = action[:confirm] if action.has_key? :confirm
        extras[:method]  = action[:method]  if action.has_key? :method
        extras[:method]  = action[:method]  if action.has_key? :method
        extras[:onclick] = action[:onclick] if action.has_key? :onclick
        extras[:id]      = action[:id]      if action.has_key? :id
        extras[:class] = action[:class] if action.has_key? :class

        link_to action[:name], action[:url], extras
      else
        nil
      end
    end.compact.join(' | ').html_safe
  end

  def tag_list(object)
    tags = Tag.list_by_object(object)
    return '--' if tags.empty?

    tags.collect do |tag|
      link_to h(tag), project_tag_path(object.project_id, CGI.escape(tag))
    end.join(', ').html_safe
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
    I18n.l(time, :format => format.to_sym)
  end

  def yesno_toggle(object_name, method, options = {})
    radio_button(object_name, method, "true", options.merge({:id => "#{options[:id]}Yes"}))    +
    " <label for=\"#{options[:id]}Yes\" class=\"#{options[:class]}\">#{I18n.t('yesno_yes')}</label> ".html_safe +
    radio_button(object_name, method, "false", options.merge({:id => "#{options[:id]}No"}))    +
    " <label for=\"#{options[:id]}No\" class=\"#{options[:class]}\">#{I18n.t('yesno_no')}</label>".html_safe
  end

  def yesno_toggle_tag(name, is_yes, options = {})
    radio_button_tag(name, "1", is_yes, options.merge({:id => "#{options[:id]}Yes"})) +
      " <label for=\"#{options[:id]}Yes\" class=\"#{options[:class]}\">#{I18n.t('yesno_yes')}</label> ".html_safe +
      radio_button_tag(name, "0", !is_yes, options.merge({:id => "#{options[:id]}No"})) +
      " <label for=\"#{options[:id]}No\" class=\"#{options[:class]}\">#{I18n.t('yesno_no')}</label>".html_safe
  end
	
	def actions_for_user(user)
	   profile_updateable = can?(:update_profile, user)
	   
	   actions = [{:name => I18n.t('edit'), :url => edit_user_path(:id => user.id), :cond => profile_updateable}]
	   
	   if @active_project.nil?
	     actions += [
	       {:name => I18n.t('delete'), :url => user_path(:id => user.id), :cond => can?(:delete,user), :method => :delete, :confirm => I18n.t('confirm_user_delete')},
	       {:name => I18n.t('permissions'), :url => permissions_user_path(:id => user.id), :cond => can?(:update_permissions, user)}]
	   else
	     actions << {:name => I18n.t('remove'), :url => users_project_path(:id => @active_project.id, :user => user.id), :cond => can?(:delete,user), :method => :delete, :confirm => I18n.t('confirm_user_remove')}
	   end
	   
	   actions
	end

  def actions_for_project(project)
    [{:name => I18n.t('edit'),   :url => edit_project_path(:id => project.id), :cond => can?(:edit,project)},
     {:name => I18n.t('delete'), :url => project_path(:id => project.id), :cond => can?(:delete,project), :method => :delete, :confirm => I18n.t('project_confirm_delete')}]
  end

  def actions_for_milestone(milestone)
    [{:name => I18n.t('edit'),   :url => edit_milestone_path(:id => milestone.id), :cond => can?(:edit,milestone)},
     {:name => I18n.t('delete'), :url => milestone_path(:id => milestone.id), :cond => can?(:delete,milestone), :class => 'oaction', :method => :delete, :confirm => I18n.t('milestone_confirm_delete')}]
  end

  def actions_for_task_list(task_list)
    [{:name => I18n.t('edit'),          :url => edit_task_list_path(:id => task_list.id), :cond => can?(:edit,task_list)},
     {:name => I18n.t('delete'),        :url => task_list_path(:id => task_list.id), :cond => can?(:delete,task_list), :class => 'oaction', :method => :delete, :confirm => I18n.t('task_list_confirm_delete')},
     {:name => I18n.t('reorder_tasks'), :url => reorder_task_list_path(:id => task_list.id), :class => 'doSortTaskList', :cond => can?(:edit,task_list)}]
  end

  def actions_for_message(message)
    [{:name => I18n.t('edit'),   :url => edit_message_path(:id => message.id), :cond => can?(:edit,message)},
     {:name => I18n.t('delete'), :url => message_path(:id => message.id), :cond => can?(:delete,message), :method => :delete, :confirm => I18n.t('message_confirm_delete')}]
  end

  def actions_for_company(company)
    actions = [
      {:name => I18n.t('add_user'), :url => "/users/new?company_id=#{company.id}", :cond => (@active_project.nil? and can?(:create_user, current_user))}, 
      {:name => I18n.t('edit'),   :url => edit_company_path(:id => company.id), :cond => can?(:edit,company)}]
    
    unless @active_project.nil?
      actions << {:name => I18n.t('remove'), :url => companies_project_path(:id => @active_project.id, :company_id => company.id), :cond => can?(:remove, company), :method => :delete, :confirm => I18n.t('confirm_client_remove')}
    else
      actions << {:name => I18n.t('permissions'), :url => permissions_company_path(:id => company.id), :cond => can?(:manage, company)}
    end
    
    actions
  end

  def actions_for_comment(comment)
    [{:name => I18n.t('edit'),   :url => edit_comment_path(:id => comment.id),   :cond => can?(:edit,comment)},
     {:name => I18n.t('delete'), :url => comment_path(:id => comment.id), :cond => can?(:delete,comment), :method => :delete, :confirm => I18n.t('comment_delete_confirm')}]
  end

  def actions_for_file(file, last_revision)
    [{:name => I18n.t('details_size', :size => format_size(last_revision.filesize)), :url => file_path(:id => file.id), :cond => can?(:download, file)},
     {:name => I18n.t('edit'),   :url => edit_file_path(:id => file.id), :cond => can?(:edit,file)},
     {:name => I18n.t('delete'), :url => file_path(:id => file.id), :cond => can?(:delete,file), :method => :delete, :confirm => I18n.t('file_delete_confirmation')}]
  end

  def actions_for_file_revision(file, revision)
    [{:name => I18n.t('download_size', :size => format_size(revision.filesize)), :url => download_file_path(:id => file.id, :revision => revision.revision_number), :cond => can?(:download, file)},
     {:name => I18n.t('edit'),                                                             :url => edit_file_path(:id => file.id, :revision => revision.revision_number), :cond => can?(:edit,file)}]
  end

  def actions_for_attached_files(attached_file, object)
    [{:name => I18n.t('details'), :url => file_path(:id => attached_file.id), :cond => true},
     {:name => I18n.t('detatch'), :url => detatch_file_path(:id => attached_file.id, :object_type => object.class.to_s, :object_id => object.id), :cond => can?(:add_file, object), :method => :put, :confirm => I18n.t('detatch_file_confirm')}]
  end

  def actions_for_time(time)
    [{:name => I18n.t('details'), :url => time_path(:id => time.id), :cond => true},
     {:name => I18n.t('edit'),    :url => edit_time_path(:id => time.id), :cond => can?(:edit,time)},
     {:name => I18n.t('delete'),  :url => time_path(:id => time.id), :cond => can?(:delete,time), :method => :delete, :confirm => I18n.t('time_confirm_delete')}]
  end

  def actions_for_time_short(time)
    [{:name => I18n.t('edit'),    :url => edit_time_path(:id => time.id), :cond => can?(:edit,time)},
     {:name => I18n.t('delete'),  :url => time_path(:id => time.id), :cond => can?(:delete,time), :method => :delete, :confirm => I18n.t('time_confirm_delete')}]
  end

  def actions_for_wiki_page(page)
    [{:name => I18n.t('edit'),    :url => {:controller => 'wiki_pages', :action => 'edit',   :id => page.slug}, :cond => can?(:edit,page)},
     {:name => I18n.t('delete'),  :url => {:controller => 'wiki_pages', :action => 'destroy', :id => page.slug}, :cond => can?(:delete,page), :method => :delete, :confirm => I18n.t('wiki_page_confirm_delete')}]
  end
  
  def running_time_for_task(task)
    @running_times.each do |time|
      if time.task_id == task.id
        return time
      end
    end
    
    nil
  end
  
  def cal_table(in_rows, tableclass)
    rows = in_rows.map do |row|
      columns = row.map do |column|
        case column[0]
          when :mday
            "<td>#{column[1]}</td>"
          when :bday
            "<td class=\"blank\">#{column[1]}</td>"
          when :th
            "<th>#{column[1]}</th>"
          when :thm
            "<th class=\"month\" rowspan=\"#{column[2]}\">#{column[1]}</th>"
        end
      end
      "<tr>#{columns.join}</tr>"
    end
    "<table class=\"#{tableclass}\"><tbody>#{rows.join}</tbody></table>".html_safe
  end
  
  # offset: Use date.wday, so use 0 to start the week in sunday
  def calendar_wdays(starting_day = 0)
    start_week = Date.today.beginning_of_week + (starting_day - 1).days # In rails week start in monday and monday.wday is 1
    (start_week...start_week+7.days).collect { |day| I18n.l(day, :format => '%A') }
  end
  
  # offset: Use date.wday, so use 0 to start the week in sunday
  def months_calendar(start_date, end_date, tableclass, starting_day=0, merge_month=false)
    # Day header
    header = ['', *calendar_wdays(starting_day)].map { |content| [:th, content]}

    end_date = end_date.end_of_month
    months = []
    until start_date > end_date
      months << (start_date.beginning_of_month..start_date.end_of_month)
      start_date += 1.month
    end

    # Iterate until final month
    rows = months.inject([header]) do |all_rows, month_dates|
      first_day = month_dates.first
      start_of_month = (first_day - (first_day.beginning_of_week + (starting_day - 1).days)) % 7
      month_dates = month_dates.to_a

      if merge_month
        # Add the days of the previous and next months
        month_dates.unshift *(month_dates.first-start_of_month.days...month_dates.first).to_a
        missing = 7 - month_dates.size % 7
        month_dates.concat((month_dates.last+1.day..month_dates.last+missing.days).to_a) unless missing == 7
      else
        month_dates.unshift *[nil] * start_of_month
      end

      week_rows = month_dates.in_groups_of(7).collect do |week|
        week.collect do |cur_date|
          if cur_date.nil? || cur_date.month != first_day.month
            [:bday, cur_date.try(:day)]
          else
            [:mday, yield(cur_date)]
          end
        end
      end

      month_cell = [:thm, I18n.l(first_day, :format => '%B'), week_rows.size + 1]
      all_rows.concat [[month_cell], *week_rows]
    end
    
    cal_table(rows, tableclass)
  end

  def days_calendar(start_date, end_date, tableclass)
    # Day header
    header = (Date.today..Date.today+6.days).map { |date| [:th, I18n.l(date, :format => '%A')] }
    
    # Iterate until final day
    rows = (start_date..end_date).to_a.in_groups_of(7).inject([header]) do |rows, week|
      rows << week.collect {|cur_date| [:mday, cur_date.nil? ? '' : yield(cur_date)]}
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
    
    "<div class=\"#{classname}\">#{content} #{list}</div>".html_safe
  end

  def textilize(text)
    return '' if text.blank?

    textilized = RedCloth.new(text, [ :hard_breaks, :filter_html ])
    textilized.hard_breaks = true if textilized.respond_to?('hard_breaks=')
    textilized.to_html.html_safe
  end
end
