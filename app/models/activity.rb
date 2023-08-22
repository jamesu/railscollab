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

class Activity < ApplicationRecord
  belongs_to :project, optional: true
  belongs_to :created_by, class_name: 'User', foreign_key:  'created_by_id'
  belongs_to :rel_object, polymorphic:  true, optional: true

  scope :is_public, -> { where(:is_private => false) }

  before_create :process_params

  @@action_lookup = {:add => 0, :upload => 1, :open => 2, :close => 3, :edit => 4, :delete => 5}
  @@action_id_lookup = @@action_lookup.invert

  def process_params
  end

  def friendly_action
    I18n.t "action_#{self.action}"
  end

  def action
  	@@action_id_lookup[self.action_id]
  end

  def action=(val)
  	self.action_id = @@action_lookup[val.to_sym]
  end

  def is_today?
    self.created_on.to_date >= Date.today and self.created_on.to_date < Date.tomorrow
  end

  def is_yesterday?
    self.created_on.to_date >= Date.yesterday and self.created_on.to_date < Date.today
  end

  def self.new_log(obj, user, action, private=false, real_project=nil)
    really_silent = Rails.configuration.x.railscollab.log_really_silent && action == :delete
    unless really_silent
      # Lets go...
      @log = Activity.new()

      @log.action = action
      if action == :delete
        @log.rel_object_id = nil
        @log.rel_object_type = obj.class.to_s
      else
        @log.rel_object = obj
      end
      @log.object_name = obj.object_name

      @log.project = nil
      if real_project.nil?
        if obj.is_a?(Project)
          if action == :delete
            @log.project_id = 0
          else
            @log.project = obj
          end
        elsif obj.respond_to? :project
          @log.project = obj.project
        end
      else
        @log.project = real_project
      end

      @log.created_by = user
      unless user.nil?
        user.last_activity = Time.now.utc
        user.save
      end
      @log.is_private = private
      @log.save
    else
      # Destroy all occurrences of this object from the log
      # (assuming no audit trail is required here)
      Activity.where({'rel_object_type' => obj.class.to_s, 'rel_object_id' => obj.id}).destroy_all
    end
  end

  def self.logs_for(project, include_private, include_silent, limit=50)
    conditions = if project.class == Array
      {:project_id => project}
    else
      {:project_id => project.id}
    end

    private_conditions = {}
    private_conditions[:is_private] = 0 unless include_private
    private_conditions[:is_silent] = 0 unless include_silent

    Activity.where(conditions).where(private_conditions).order('created_on DESC').limit(limit)
  end
end
