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

module ProjectItemsHelper
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

  private
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
end
