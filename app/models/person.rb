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

class Person < ActiveRecord::Base
  belongs_to :user
  belongs_to :project

  before_create :ensure_permissions

  # Update these when required
  @@permission_fields = [
    :can_manage_messages,
    :can_manage_tasks,
    :can_manage_milestones,
    :can_manage_time,
    :can_upload_files,
    :can_manage_files,
    :can_assign_to_owners,
    :can_assign_to_other,
    :can_manage_wiki_pages
  ]

  def ensure_permissions(set_val=true)
    @@permission_fields.each do |field|
      self[field] ||= set_val
    end
  end

  def update_str(vals)
    vals.each do |val|
      self[val] = true
    end

    self
  end

  def reset_permissions
    @@permission_fields.each{ |field| self[field] = false }
    self
  end

  def has_all_permissions?
    @@permission_fields.all?{ |field| self[field] }
  end

  def self.permission_names()
    vals = {}
    @@permission_fields.each{ |field| vals[field] = I18n.t(field) }
    vals
  end

  def self.check_permission(user, project, permission)
    Person.where(['project_id = ? AND user_id = ? AND ? = 1', project.id, user.id, permission]).select([:user_id, :username])
  end
end
