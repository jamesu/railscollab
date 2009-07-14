#==
# RailsCollab
# Copyright (C) 2007 - 2008 James S Urquhart
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

module MessageHelper
  def page_title
    case action_name
      when 'category' then :category_messages.l_with_args(:category => @current_category.name)
      else super
    end
  end

  def current_tab
    :messages
  end

  def current_crumb
    case action_name
      when 'index' then :messages
      when 'add_category' then :add_message_category
      when 'add' then :add_message
      when 'edit_category' then :edit_message_category
      when 'edit' then :edit_message
      when 'view' then @message.title
      when 'category' then @current_category.name
      else super
    end
  end

  def extra_crumbs
    crumbs = []
    crumbs << {:title => :messages, :url => "/project/#{@active_project.id}/message"} unless action_name == 'index'
    crumbs << {:title => @message.project_message_category.name, :url => "/project/#{@active_project.id}/message/category/#{@message.category_id}"} if action_name == 'view'
    crumbs
  end

  def additional_stylesheets
    ['project/messages']
  end
end
