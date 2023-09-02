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
    html_escape Rails.configuration.railscollab.site_name
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
    mthd = attrs[:method] || :post
    link_to "<img src='#{icon_url}' alt='' />".html_safe, link, attrs.merge({:method => mthd, :class => 'checkboxLink', :title => ( hint.nil? ? '' : (html_escape hint) )})
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
        extras[:data] = action[:data] if action.has_key? :data

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
	       {:name => I18n.t('delete'), :url => user_path(:id => user.id), :cond => can?(:delete,user), :data => { turbo_method: :delete, :turbo_confirm => I18n.t('confirm_user_delete') }},
	       {:name => I18n.t('permissions'), :url => permissions_user_path(:id => user.id), :cond => can?(:update_permissions, user)}]
	   else
	     actions << {:name => I18n.t('remove'), :url => users_project_path(:id => @active_project.id, :user => user.id), :cond => can?(:delete,user), :data => { turbo_method: :delete, :turbo_confirm => I18n.t('confirm_user_remove') }}
	   end
	   
	   actions
	end

  def actions_for_project(project)
    [{:name => I18n.t('edit'),   :url => edit_project_path(:id => project.id), :cond => can?(:edit,project)},
     {:name => I18n.t('delete'), :url => project_path(:id => project.id), :cond => can?(:delete,project), :data => { turbo_method: :delete, :turbo_confirm => I18n.t('project_confirm_delete') }}]
  end

  def actions_for_milestone(milestone)
    [{:name => I18n.t('edit'),   :url => edit_project_milestone_path(milestone.project, :id => milestone.id), :cond => can?(:edit,milestone)},
     {:name => I18n.t('delete'), :url => project_milestone_path(milestone.project, :id => milestone.id), :cond => can?(:delete,milestone), :class => 'oaction', :data => { turbo_method: :delete, :turbo_confirm => I18n.t('milestone_confirm_delete') }}]
  end

  def actions_for_task_list(task_list)
    [{:name => I18n.t('edit'),          :url => edit_project_task_list_path(task_list.project, :id => task_list.id), :cond => can?(:edit,task_list)},
     {:name => I18n.t('delete'),        :url => project_task_list_path(task_list.project, :id => task_list.id), :cond => can?(:delete,task_list), :class => 'oaction', :data => { turbo_method: :delete, :turbo_confirm => I18n.t('task_list_confirm_delete') }},
     {:name => I18n.t('reorder_tasks'), :url => reorder_project_task_list_path(task_list.project, :id => task_list.id), :class => 'doSortTaskList', :cond => can?(:edit,task_list)}]
  end

  def actions_for_message(message)
    [{:name => I18n.t('edit'),   :url => edit_project_message_path(message.project, :id => message.id), :cond => can?(:edit,message)},
     {:name => I18n.t('delete'), :url => project_message_path(message.project, :id => message.id), :cond => can?(:delete,message), :data => { turbo_method: :delete, :turbo_confirm => I18n.t('message_confirm_delete') }}]
  end

  def actions_for_company(company)
    actions = [
      {:name => I18n.t('add_user'), :url => "/users/new?company_id=#{company.id}", :cond => (@active_project.nil? and can?(:create_user, current_user))}, 
      {:name => I18n.t('edit'),   :url => edit_company_path(:id => company.id), :cond => can?(:edit,company)}]
    
    unless @active_project.nil?
      actions << {:name => I18n.t('remove'), :url => companies_project_path(:id => @active_project.id, :company_id => company.id), :cond => can?(:remove, company), :data => { turbo_method: :delete, :turbo_confirm => I18n.t('confirm_client_remove') }}
    else
      actions << {:name => I18n.t('permissions'), :url => permissions_company_path(:id => company.id), :cond => can?(:manage, company)}
    end
    
    actions
  end

  def actions_for_comment(comment)
    [{:name => I18n.t('edit'),   :url => edit_project_comment_path(comment.project, :id => comment.id),   :cond => can?(:edit,comment)},
     {:name => I18n.t('delete'), :url => project_comment_path(comment.project, :id => comment.id), :cond => can?(:delete,comment), :data => { turbo_method: :delete, :turbo_confirm => I18n.t('comment_delete_confirm') }}]
  end

  def actions_for_file(file, last_revision)
    [{:name => I18n.t('details_size', :size => format_size(last_revision.filesize)), :url => project_file_path(file.project, :id => file.id), :cond => can?(:download, file)},
     {:name => I18n.t('edit'),   :url => edit_project_file_path(file.project, :id => file.id), :cond => can?(:edit,file)},
     {:name => I18n.t('delete'), :url => project_file_path(file.project, :id => file.id), :cond => can?(:delete,file), :data => { turbo_method: :delete, :turbo_confirm => I18n.t('file_delete_confirmation') }}]
  end

  def actions_for_file_revision(file, revision)
    [{:name => I18n.t('download_size', :size => format_size(revision.filesize)), :url => download_project_file_path(file.project, :id => file.id, :revision => revision.revision_number), :cond => can?(:download, file)},
     {:name => I18n.t('edit'),                                                   :url => edit_project_file_path(file.project, :id => file.id, :revision => revision.revision_number), :cond => can?(:edit,file)}]
  end

  def actions_for_attached_files(attached_file, object)
    [{:name => I18n.t('details'), :url => project_file_path(attached_file.project, :id => attached_file.id), :cond => true},
     {:name => I18n.t('detatch'), :url => detatch_project_file_path(attached_file.project, :id => attached_file.id, :object_type => object.class.to_s, :object_id => object.id), :cond => can?(:add_file, object), :data => { turbo_method: :delete, :turbo_confirm => I18n.t('detatch_file_confirm') }}]
  end

  def actions_for_time(time)
    [{:name => I18n.t('details'), :url => project_time_path(time.project, :id => time.id), :cond => true},
     {:name => I18n.t('edit'),    :url => edit_project_time_path(time.project, :id => time.id), :cond => can?(:edit,time)},
     {:name => I18n.t('delete'),  :url => project_time_path(@actitime.project_project, :id => time.id), :cond => can?(:delete,time), :data => { turbo_method: :delete, :turbo_confirm => I18n.t('time_confirm_delete') }}]
  end

  def actions_for_time_short(time)
    [{:name => I18n.t('edit'),    :url => edit_project_time_path(time.project, :id => time.id), :cond => can?(:edit,time)},
     {:name => I18n.t('delete'),  :url => project_time_path(time.project, :id => time.id), :cond => can?(:delete,time), :data => { turbo_method: :delete, :turbo_confirm => I18n.t('time_confirm_delete') }}]
  end

  def actions_for_wiki_page(page)
    [{:name => I18n.t('edit'),    :url => edit_project_wiki_page_path(page.project, :id => page.slug), :cond => can?(:edit,page)},
     {:name => I18n.t('delete'),  :url => project_wiki_page_path(page.project, :id => page.slug), :cond => can?(:delete,page), :data => { turbo_method: :delete, :turbo_confirm => I18n.t('wiki_page_confirm_delete') }}]
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

  def textilize(text, lite=false, force_attrs=nil)
    if text.blank?
      ""
    else

      renderer = Redcarpet::Render::HTML.new
      markdown = Redcarpet::Markdown.new(renderer)
      text = markdown.render(text).html_safe

      unless force_attrs.nil?
        attrs = force_attrs.map{ |key,value| "#{key}='#{value}'"}.join(' ')
        text.gsub(/<\b([a-z]*)\w/, "\\0 #{attrs}")
      else
        text
      end
    end
  end

  def can?(ability, instance)
    return false if @logged_user.nil?
    if @logged_user_can.nil?
      @logged_user_can = Ability.new.init(@logged_user)
    end
    return @logged_user_can.can?(ability, instance)
  end

  # Navigation

  def page_title
    @page_title
  end

  def current_crumb
    @current_crumb
  end

  def crumbs
    @crumbs
  end

  def extra_crumbs
    @extra_crumbs
  end

  def page_actions
    @page_actions
  end

  def current_tab
    @current_tab
  end

  def config_page
    @page_title = page_title
    @crumbs = crumbs
    @current_tab = current_tab
    @current_crumb = current_crumb
    @extra_crumbs = extra_crumbs
    @page_actions = page_actions
  end

  def administration_tabbed_navigation
    return nil if !@logged_user.company.is_owner?
    items = [
      {:id => :index,         :url => administration_path},
      {:id => :people,        :url => companies_path},
      {:id => :projects,      :url => projects_path}
    ]
  end

  def administration_crumbs
    return nil if !@logged_user.company.is_owner?
    [
      {:title => :dashboard,      :url => '/dashboard'},
      {:title => :administration, :url => '/administration'}
    ] + extra_crumbs + [{:title => current_crumb}]
  end

  def dashboard_tabbed_navigation
    items = [{:id => :overview,       :url => '/dashboard/index'},
             {:id => :my_projects,    :url => '/dashboard/my_projects'},
             {:id => :my_tasks,       :url => '/dashboard/my_tasks'},
             {:id => :milestones,     :url => '/dashboard/milestones'}]
  end

  def dashboard_crumbs
    [{:title => :dashboard, :url => '/dashboard'}, {:title => current_crumb}]
  end

  def project_tabbed_navigation
    project_id = @active_project.id
    items = [{:id => :overview,   :url => project_path(@active_project)}]
    items << {:id => :messages,   :url => project_messages_path(@active_project)}
    items << {:id => :tasks,      :url => project_task_lists_path(@active_project)}
    items << {:id => :milestones, :url => project_milestones_path(@active_project)}
    items << {:id => :ptime,      :url => project_times_path(@active_project)} if @logged_user.has_permission(@active_project, :can_manage_time)
    items << {:id => :files,      :url => project_files_path(@active_project)}
    items << {:id => :wiki,       :url => project_wiki_pages_path(@active_project)}
    items << {:id => :people,     :url => people_project_path(@active_project)}

    items
  end

  def project_crumbs(current=nil, extras=[])
    [
      {:title => :dashboard,           :url => '/dashboard'},
      {:title => @active_project.name, :url => project_path(:id => @active_project.id)}
    ] + extra_crumbs + [{:title => current_crumb}]
  end

  # Project items

  def assign_project_select(object, method, project, options = {})
    select_tag "#{object}[#{method}]", assign_select_grouped_options(project, :selected => (options.delete(:object) || instance_variable_get("@#{object}")).try(method)), {:id => "#{object}_#{method}"}.merge(options)
  end

  def task_collection_select(object, method, collection, filter=nil, options = {})
    select_tag "#{object}[#{method}]", task_select_grouped_options(collection, filter, :selected => (options.delete(:object) || instance_variable_get("@#{object}")).try(method)), {:id => "#{object}_#{method}"}.merge(options)
  end

  def select_file_options(project, current_object=nil)
    file_ids = current_object.nil? ? [] : current_object.project_file_ids
    
    conds = {'project_id' => project.id, 'is_visible' => true}
    conds['is_private'] = false unless @logged_user.member_of_owner?

    [['-- None --', 0]] + ProjectFile.where(conds).select('id, filename').collect do |file|
      if file_ids.include?(file.id)
        nil
      else
        [file.filename, file.id]
      end
    end.compact
  end

  def select_milestone_options(project)
    conds = {'project_id' => project.id}
    conds['is_private'] = false unless @logged_user.member_of_owner?
    
    [['-- None --', 0]] + Milestone.where(conds).select('id, name').collect do |milestone|
      [milestone.name, milestone.id]
    end
  end

  def select_message_options(project)
    conds = {'project_id' => project.id}
    conds['is_private'] = false unless @logged_user.member_of_owner?
    
    Message.where(conds).select('id, title').collect do |message|
      [message.title, message.id]
    end
  end

  def assign_select_grouped_options(project, options = {})
    permissions = @logged_user.permissions_for(project)
    return [] if permissions.nil? or !(permissions.can_assign_to_owners or permissions.can_assign_to_other)

    default_option = permissions.can_assign_to_other ? content_tag(:option, I18n.t('anyone'), :value => 0) : ''
    items = {}
    project.companies.each do |company|
      next if company.is_owner? and !permissions.can_assign_to_owners
      next if !company.is_owner? and !permissions.can_assign_to_other

      items[company.name] = [[I18n.t('anyone'), "c#{company.id}"], *company.users.collect do |user|
        [user.username, user.id.to_s] if user.member_of(project)
      end.compact]
    end

    default_option + grouped_options_for_select(items, options)
  end

  def task_select_grouped_options(task_lists, filter=nil, options = {})
    items = {}
    task_lists.each do |task_list|
      list = filter.nil? ? task_list.tasks : task_list.tasks.reject(&filter)
      items[task_list.name] = list.collect {|task| [truncate(task.text, :length => 50), task.id.to_s]}
    end

    content_tag(:option, I18n.t('none'), :value => 0) + grouped_options_for_select(items, options)
  end
  
  def object_comments_url(object)
    # comments 
    "#{object.object_url}/comments"
  end

  def error_messages_for(object, other=nil)
  end

  def filetype_icon_url(file)
    if file.is_a?(ProjectFile)
      file.project_file_revisions.empty? ? "/assets/filetypes/unknown.png" : filetype_icon_url(file.project_file_revisions[0])
    else
      if !file.has_thumbnail
        ext = file.file_type ? file.file_type.icon : "unknown.png"
        return "/assets/filetypes/#{ext}"
      else
        url_for file.data.variant(:thumb)
      end
    end
  end
end
