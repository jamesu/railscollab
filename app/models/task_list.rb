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

class TaskList < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :milestone, optional: true
  belongs_to :project
  belongs_to :completed_by, class_name: "User", foreign_key: "completed_by_id", optional: true
  belongs_to :created_by, class_name: "User", foreign_key: "created_by_id"
  belongs_to :updated_by, class_name: "User", foreign_key: "updated_by_id", optional: true

  has_many :tasks, dependent: :destroy

  #has_many :tags, as:  'rel_object', dependent:  :destroy

  scope :is_public, -> { where(is_private: false) }
  scope :is_open, -> { where("task_lists.completed_on IS NULL") }
  scope :completed, -> { where("task_lists.completed_on IS NOT NULL") }

  before_validation :process_params, on: :create
  after_create :process_create
  before_update :process_update_params
  before_destroy :process_destroy

  def ordered_tasks
    self.tasks.order(order: :asc)
  end

  def process_params
    write_attribute("completed_on", nil)
  end

  def process_create
    new_tags(@new_tags)
    Activity.new_log(self, self.created_by, :add, self.is_private)
  end

  def process_update_params
    update_tags(@new_tags)
    return unless @ensured_complete.nil?

    Activity.new_log(self, self.updated_by, :edit, self.is_private)
  end

  def process_destroy
    Tag.clear_by_object(self)
    Activity.new_log(self, self.updated_by, :delete, self.is_private)
  end

  def ensure_completed(completed_by)
    # If we don't think we are complete either, exit (vice versa)
    @ensured_complete = true
    self.tasks.reload

    # Ok now lets check if we are *really* complete
    if self.finished_all_tasks?
      if self.completed_on.nil?
        write_attribute("completed_on", Time.now.utc)
        self.completed_by = completed_by
        Activity.new_log(self, completed_by, :close, self.is_private)
      end
    else
      unless self.completed_on.nil?
        write_attribute("completed_on", nil)
        Activity.new_log(self, completed_by, :open, self.is_private)
      end
    end
  end

  def object_name
    self.name
  end

  def object_url(host = nil)
    project_task_list_url(self, only_path: host.nil?, host: host, project_id: self.project_id)
  end

  def is_completed?
    self.completed_on != nil
  end

  def send_comment_notifications(comment)
  end

  def open_tasks
    self.tasks.select { |task| task.completed_on.nil? }
  end

  def completed_tasks
    self.tasks.reject { |task| task.completed_on.nil? }
  end

  def finished_all_tasks?
    completed_count = 0

    self.tasks.each do |task|
      completed_count += 1 unless task.completed_on.nil?
    end

    completed_count > 0 and completed_count == self.tasks.length
  end

  def self.select_list(project)
    TaskList.where(project_id: project.id).select("id, name").collect do |tasklist|
      [tasklist.name, tasklist.id]
    end
  end

  # Serialization

  def to_xml(options = {}, &block)
    default_options = {
      methods: [:tags],
      only: [
        :id,
        :milestone_id,
        :priority,
        :name,
        :description,
        :is_private,
      ],
    }
    super(options.merge(default_options), &block)
  end

  # Accesibility

  #attr_accessible :name, :priority, :description, :milestone_id, :is_private, :tags

  # Validation

  validates_presence_of :name
  validates_each :milestone, allow_nil: true do |record, attr, value|
    record.errors.add(attr, I18n.t("not_part_of_project")) if value.project_id != record.project_id
  end

  validates_each :is_private, if: Proc.new { |obj| !obj.last_edited_by_owner? } do |record, attr, value|
    record.errors.add(attr, I18n.t("not_allowed")) if value == true
  end

  # Search
  register_meilisearch
end
