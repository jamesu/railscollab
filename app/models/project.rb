#==
# RailsCollab
# Copyright (C) 2007 - 2011 James S Urquhart
# Portions Copyright (C) René Scheibe
# Portions Copyright (C) Ariejan de Vroom
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

class Project < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :completed_by, class_name: "User", foreign_key: "completed_by_id", optional: true
  belongs_to :created_by, class_name: "User", foreign_key: "created_by_id"
  belongs_to :updated_by, class_name: "User", foreign_key: "updated_by_id", optional: true

  has_many :people
  has_many :users, through: :people
  has_many :comments

  has_many :time_records, dependent: :destroy
  has_many :tags, as: :rel_object # Dependent objects sould destroy all of these for us

  has_many :milestones, dependent: :destroy

  has_many :task_lists, dependent: :destroy

  has_many :tasks, through: :task_lists

  has_many :folders, dependent: :destroy
  has_many :project_files, dependent: :destroy
  has_many :messages, dependent: :destroy
  has_many :categories, dependent: :destroy

  has_many :activities, dependent: :destroy

  has_many :wiki_pages, dependent: :destroy

  has_and_belongs_to_many :companies, join_table: :project_companies

  before_create :process_params
  after_create :process_create
  before_update :process_update_params
  before_destroy :process_destroy

  def process_params
    write_attribute("completed_on", nil)
  end

  def process_create
    Activity.new_log(self, self.created_by, :add, true)
  end

  def process_update_params
    if @update_completed.nil?
      Activity.new_log(self, self.updated_by, :edit, true)
    else
      write_attribute("completed_on", @update_completed ? Time.now.utc : nil)
      self.completed_by = @update_completed_user
      Activity.new_log(self, @update_completed_user, @update_completed ? :close : :open, true)
    end
  end

  def process_destroy
    people.destroy_all
    Activity.new_log(self, self.updated_by, :delete, true)
  end

  def ordered_messages
    self.messages.order("created_on DESC")
  end

  def ordered_task_lists
    self.tasks_lists.order(order: :desc)
  end

  def ordered_activities
    self.activities.order("created_on DESC, id DESC")
  end

  def object_name
    self.name
  end

  def object_url(host = nil)
    project_url(self, only_path: host.nil?, host: host)
  end

  def tasks_by_user(user, completed = false)
    self.tasks.where(["((assigned_to_company_id = ? OR assigned_to_user_id = ?) OR (assigned_to_company_id = 0 OR assigned_to_user_id = 0)) AND tasks.completed_on #{completed ? "IS NOT" : "IS"} NULL", user.company_id, user.id])
  end

  def is_active?
    return self.completed_on == nil
  end

  def milestones_by_user(user, completed = false)
    Milestone.where(["project_id = #{self.id} AND ((assigned_to_company_id = ? OR assigned_to_user_id = ?) OR (assigned_to_company_id = 0 OR assigned_to_user_id = 0)) AND completed_on #{completed ? "IS NOT" : "IS"} NULL", user.company_id, user.id])
  end

  def has_member(user)
    return Person.where("project_id = #{self.id} AND user_id = #{user.id}", select: "user_id")
  end

  def set_completed(value, user = nil)
    @update_completed = value
    @update_completed_user = user
  end

  def search(query, is_private, options = {}, tag_search = false)
    self.class.search(query, is_private, [self], options, tag_search)
  end

  def self.search_for_user(query, user, options = {}, tag_search = false)
    self.search(query, !user.member_of_owner?, user.active_projects, options, tag_search)
  end

  def self.search(query, is_private, projects, options = {}, tag_search = false)
    results = []
    return results, 0 if !Rails.configuration.railscollab.search_enabled or query.blank?

    filters = []
    filters << ('(' + projects.map{ |pr| "project.id = #{pr.id}" }.join(' OR ') + ')')
    total = 0
    results = []

    if tag_search
      # Use tag index for tag search
      items = Tag.index.search(query,  { filter: filters.join(' AND ') })
    else
      # Use project index for everything else
      filters << "(is_private = false)" unless is_private

      items = Project.index.search(query,  { filter: filters.join(' AND ') })
    end
    
    item_list = items['hits'].map do |entry|
      Kernel.const_get(entry['class_name'].to_sym).find(entry['id'])
    end.compact

    total = item_list.count

    return item_list, total
  end

  # Helpers

  def self.select_list
    Project.all.collect do |project|
      [project.name, project.id]
    end
  end

  # Accesibility

  #attr_accessible :name, :description, :priority, :show_description_in_overview

  # Search
  register_meilisearch

  # Validation

  validates_presence_of :name
end
