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

module CategoriesHelper
  def page_title
    case action_name
      when 'posts' then  @category.name
      else super
    end
  end

  def current_tab
    :messages
  end

  def current_crumb
    case action_name
      when 'new', 'create' then :add_message_category
      when 'edit', 'update' then :edit_message_category
      when 'index' then :messages
      when 'posts' then @category.name
      else super
    end
  end

  def extra_crumbs
    crumbs = []
    crumbs << {:title => :messages, :url => "/project/#{@active_project.id}/messages"}
    crumbs
  end

  def page_actions
    @page_actions = []
    
    if ProjectMessageCategory.can_be_created_by(@logged_user, @active_project)
      @page_actions << {:title => :add_category, :url => new_category_path } if action_name == 'index'
    end
    
    if ProjectMessage.can_be_created_by(@logged_user, @active_project)
      @page_actions << {:title => :add_message, :url => new_message_path(:category_id => @category.id)} if action_name == 'posts'
    end
    
    @page_actions
  end
end
