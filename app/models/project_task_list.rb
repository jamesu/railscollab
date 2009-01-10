#==
# RailsCollab
# Copyright (C) 2007 - 2008 James S Urquhart
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

class ProjectTaskList < ActiveRecord::Base
  include ActionController::UrlWriter

  belongs_to :project_milestone, :foreign_key => 'milestone_id'
  belongs_to :project
  belongs_to :completed_by, :class_name => 'User', :foreign_key => 'completed_by_id'
  belongs_to :created_by,   :class_name => 'User', :foreign_key => 'created_by_id'
  belongs_to :updated_by,   :class_name => 'User', :foreign_key => 'updated_by_id'

  has_many :project_tasks, :foreign_key => 'task_list_id', :order => "#{self.connection.quote_column_name 'order'} ASC", :dependent => :destroy

  #has_many :tags, :as => 'rel_object', :dependent => :destroy

  acts_as_ferret :fields => [:name, :description, :project_id, :is_private, :tags_with_spaces], :store_class_name => true

  before_validation_on_create  :process_params
  after_create   :process_create
  before_update  :process_update_params
  after_update   :update_tags
  before_destroy :process_destroy

  def update_tags
    return true if @update_tags.nil?
    Tag.clear_by_object(self)
    Tag.set_to_object(self, @update_tags)
    
    true
  end

  def process_params
    write_attribute("completed_on", nil)
  end

  def process_create
    ApplicationLog.new_log(self, self.created_by, :add, self.is_private)
    update_tags
  end

  def process_update_params
    return unless @ensured_complete.nil?

    ApplicationLog.new_log(self, self.updated_by, :edit, self.is_private)
  end

  def process_destroy
    Tag.clear_by_object(self)
    ApplicationLog.new_log(self, self.updated_by, :delete, self.is_private)
  end

  def ensure_completed(task_completed, completed_by)
    # If the task isn't complete, and we don't think we are
    # complete either, exit (vice versa)
    @ensured_complete = true
    return if self.is_completed? == task_completed

    # Ok now lets check if we are *really* complete
    if self.finished_all_tasks?
      if self.completed_on.nil?
        write_attribute('completed_on', Time.now.utc)
        self.completed_by = completed_by
        ApplicationLog::new_log(self, completed_by, :close, self.is_private)
      end
    else
      unless self.completed_on.nil?
        write_attribute('completed_on', nil)
        ApplicationLog::new_log(self, completed_by, :open, self.is_private)
      end
    end
  end

  def object_name
    self.name
  end

  def object_url
    url_for :only_path => true, :controller => 'task_lists', :action => 'show', :id => self.id, :active_project => self.project_id
  end

  def tags
    return tags_list.join(',')
  end
  
  def tags_list
    @update_tags.nil? ? Tag.list_by_object(self) : @update_tags
  end

  def tags_with_spaces
    Tag.list_by_object(self).join(' ')
  end

  def tags=(val)
    @update_tags = val.split(',')
  end

  def is_completed?
    self.completed_on != nil
  end

  def last_edited_by_owner?
    self.created_by.member_of_owner? or (!self.updated_by.nil? and self.updated_by.member_of_owner?)
  end

  def send_comment_notifications(comment)
  end

  def self.can_be_created_by(user, project)
    project.is_active? and user.has_permission(project, :can_manage_tasks)
  end

  def can_be_managed_by(user)
    project.is_active? and user.has_permission(project, :can_manage_tasks)
  end

  def can_be_edited_by(user)
    return false if !project.is_active? or !user.member_of(project) or user.is_anonymous?

    return true if user.is_admin

    !(self.is_private and !user.member_of_owner?) and user.id == created_by_id
  end
  
  alias :can_be_changed_by :can_be_edited_by

  def can_be_deleted_by(user)
    project.is_active? and user.member_of(project) and user.is_admin
  end

  def can_be_seen_by(user)
    user.member_of(self.project) and !(self.is_private and !user.member_of_owner?)
  end

  def comment_can_be_added_by(user)
    project.is_active? and project.has_member(user) and !user.is_anonymous?
  end

  def open_tasks
    self.project_tasks.select{ |task| task.completed_on.nil? }
  end

  def completed_tasks
    self.project_tasks.reject{ |task| task.completed_on.nil? }
  end

  def finished_all_tasks?
    completed_count = 0

    self.project_tasks.each do |task|
      completed_count += 1 unless task.completed_on.nil?
    end

    completed_count > 0 and completed_count == self.project_tasks.length
  end

  def self.priv_scope(include_private)
    if include_private
      yield
    else
      with_scope :find => { :conditions =>  ['is_private = ?', false] } do
        yield
      end
    end
  end

  def self.select_list(project)
    ProjectTaskList.all(:conditions => ['project_id = ?', project.id], :select => 'id, name').collect do |tasklist|
      [tasklist.name, tasklist.id]
    end
  end
  
  # Serialization
  alias_method :ar_to_xml, :to_xml
  
  def to_xml(options = {}, &block)
    default_options = {
      :methods => [ :tags ],
      :only => [ 
        :id,
        :milestone_id,
        :priority,
        :name,
        :description,
        :is_private
      ]}
    self.ar_to_xml(options.merge(default_options), &block)
  end

  # Accesibility

  attr_accessible :name, :priority, :description, :milestone_id, :is_private, :tags

  # Validation

  validates_presence_of :name
  validates_each :project_milestone, :allow_nil => true do |record, attr, value|
    record.errors.add(attr, :not_part_of_project.l) if value.project_id != record.project_id
  end

  validates_each :is_private, :if => Proc.new { |obj| !obj.last_edited_by_owner? } do |record, attr, value|
    record.errors.add(attr, :not_allowed.l) if value == true
  end
end
