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

class Person < ApplicationRecord
  belongs_to :user
  belongs_to :project

  before_create :set_all_permissions

  # Update these when required
  @@permission_fields = {
    can_manage_messages: 0x1,
    can_manage_tasks: 0x2,
    can_manage_milestones: 0x4,
    can_manage_time: 0x8,
    can_upload_files: 0x10,
    can_manage_files: 0x20,
    can_assign_to_owners: 0x40,
    can_assign_to_other: 0x80,
    can_manage_wiki_pages: 0x100
  }

  def set_all_permissions
    self.code = 0xFFFFFFFF
  end

  def clear_all_permissions
    self.code = 0
  end

  def set_permission(key, enabled)
    key = key.to_sym
    bit = @@permission_fields[key]
    return if bit.nil?

    if enabled
      self.code |= bit
    else
      self.code &= ~bit
    end
  end

  def has_permission(pname)
    pname = pname.to_sym
    return false if !@@permission_fields.has_key?(pname)
    return (user.is_admin or ((self.code & @@permission_fields[pname]) != 0 ))
  end

  def set_permissions(keys)
    self.code = 0
    @@permission_fields.keys.each do |k|
      set_permission(k, true)
    end
  end

  def has_all_permissions?
    return true if user.is_admin

    @@permission_fields.each do |k,v|
      if (self.code & v) == 0
        return false
      end
    end

    return true
  end

  def self.permission_names
    vals = {}
    @@permission_fields.keys.each { |field| vals[field] = I18n.t(field) }
    vals
  end
end
