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

class Milestone < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :project

  belongs_to :company, :foreign_key => 'assigned_to_company_id'
  belongs_to :user,    :foreign_key => 'assigned_to_user_id'

  belongs_to :completed_by, :class_name => 'User', :foreign_key => 'completed_by_id'

  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
  belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'

  has_many :task_lists, :order => "#{self.connection.quote_column_name 'order'} DESC", :dependent => :nullify

  has_many :messages, :dependent => :nullify

  #has_many :tags, :as => 'rel_object', :dependent => :destroy

  scope :is_public, where(:is_private => false)
  scope :is_open, where('milestones.completed_on IS NULL').order('milestones.due_date ASC')
  scope :late, where(['due_date < ? AND completed_on IS NULL', Date.today])
  scope :todays, where(['completed_on IS NULL AND (due_date >= ? AND due_date < ?)', Date.today, Date.today+1])
  scope :upcoming, where(['completed_on IS NULL AND due_date >= ?', Date.today+1])
  scope :completed, where('completed_on IS NOT NULL')

  before_validation :process_params, :on => :create
  after_create   :process_create
  before_update  :process_update_params
  before_destroy :process_destroy

  def process_params
    write_attribute("completed_on", nil)

    if self.assigned_to_user_id.nil?
      write_attribute('assigned_to_user_id', 0)
    end
    if self.assigned_to_company_id.nil?
      write_attribute('assigned_to_company_id', 0)
    end
  end

  def process_create
    Activity.new_log(self, self.created_by, :add, self.is_private)
  end

  def process_update_params
    if self.assigned_to_user_id.nil?
      write_attribute('assigned_to_user_id', 0)
    end
    if self.assigned_to_company_id.nil?
      write_attribute('assigned_to_company_id', 0)
    end

    if @update_completed.nil?
      Activity.new_log(self, self.updated_by, :edit, self.is_private)
    else
      write_attribute('completed_on', @update_completed ? Time.now.utc : nil)
      self.completed_by = @update_completed_user
      Activity.new_log(self, @update_completed_user, @update_completed ? :close : :open, self.is_private)
    end
  end

  def process_destroy
    Tag.clear_by_object(self)
    Activity.new_log(self, self.updated_by, :delete, self.is_private)
  end

  def object_name
    self.name
  end

  def object_url(host = nil)
    url_for hash_for_milestone_path(:id => self.id, :active_project => self.project_id, :only_path => host.nil?, :host => host)
  end

  def tags
    Tag.list_by_object(self).join(',')
  end

  def tags_with_spaces
    Tag.list_by_object(self).join(' ')
  end

  def tag_list
    Tag.where(['rel_object_type = ? AND rel_object_id = ?', object.class.to_s, object.id])
  end

  def tags=(val)
    Tag.clear_by_object(self)
    Tag.set_to_object(self, val.split(',')) unless val.nil?
  end

  def assigned_to=(obj)
    self.company = obj.class == Company ? obj : nil
    self.user = obj.class == User ? obj : nil
  end

  def assigned_to
    return self.company if self.company
    return self.user    if self.user
    nil
  end

  def assigned_to_id=(val)
    # Set assigned_to accordingly
    if val.nil? or val == '0' or val == 'c0'
      self.assigned_to = nil
      return
    end

    begin
      self.assigned_to = val[0] == 99 ?
        Company.find(val[1...val.length]) :
        User.find(val)
    rescue ActiveRecord::RecordNotFound
      self.assigned_to = nil
    end
  end

  def assigned_to_id
    return "c#{self.company.id}" if self.company
    return self.user.id.to_s     if self.user
    '0'
  end

  def is_upcoming?
    self.due_date.to_date > Date.tomorrow
  end

  def is_late?
    self.due_date.to_date < Date.today
  end

  def is_today?
    self.due_date.to_date == Date.today
  end

  def is_completed?
    self.completed_on != nil
  end

  def days_left
    (self.due_date.to_date - Date.today).to_i
  end

  def days_late
    (Date.today - self.due_date.to_date).to_i
  end

  def last_edited_by_owner?
    self.created_by.member_of_owner? or (!self.updated_by.nil? and self.updated_by.member_of_owner?)
  end

  def send_comment_notifications(comment)
  end

  def set_completed(value, user=nil)
    @update_completed = value
    @update_completed_user = user
  end

  # Helpers

  def self.all_by_user(user)
    projects = user.active_projects
    project_ids = projects.collect{ |project| project.id }
    return [] if project_ids.empty?

    msg_conditions = user.member_of_owner? ?
      { :completed_on => nil, :project_id => project_ids } :
      { :completed_on => nil, :project_id => project_ids, :is_private => false }

    self.where(msg_conditions)
  end
	
  def self.all_assigned_to(user, assignee, start_time=nil, end_time=nil, real_projects=nil, exclude_inactive=false)
    project_ids = (real_projects || user.active_projects).collect { |p| p.id }
    return [] if project_ids.empty?

    # Milestone not completed, visible, and part of project(s)?
    msg_conditions = {'milestones.completed_on' => nil, 'project_id' => project_ids}
    msg_conditions['is_private'] = false unless user.member_of_owner?

    # Exclude inactive projects?
    msg_joins = nil
    if exclude_inactive
      msg_conditions['projects.completed_on'] = nil
      msg_joins = [:project]
    end
    
    # Limit by assignee
    if assignee.class == User
      msg_conditions['assigned_to_user_id'] = assignee.id
    elsif assignee.class == Company
      msg_conditions['assigned_to_company_id'] = assignee.id
    end

    # Restrict by time
    unless start_time.nil?
      time_conditions = ['due_date >= ?', start_time]
    else
      time_conditions = nil
    end

    unless end_time.nil?
      if time_conditions.nil?
        time_conditions = ['due_date <= ?', end_time]
      else
        time_conditions[0] += ' AND due_date <= ?'
        time_conditions << end_time
      end
    end

    where(time_conditions).where(msg_conditions).order('due_date ASC').joins(msg_joins)
  end

  def self.todays_by_user(user)
    from_date = Date.today
    to_date = Date.today + 1

    projects = user.active_projects
    project_ids = projects.collect{ |project| project.id}.join(',')
    return [] if project_ids.empty?

    msg_conditions = user.member_of_owner? ?
      ["completed_on IS NULL AND (due_date >= '#{from_date}' AND due_date < '#{to_date}') AND project_id IN (#{project_ids})"] :
      ["completed_on IS NULL AND (due_date >= '#{from_date}' AND due_date < '#{to_date}') AND project_id IN (#{project_ids}) AND is_private = ?", false]

    self.where(msg_conditions)
  end

  def self.late_by_user(user)
    due_date = Date.today

    projects = user.active_projects

    project_ids = projects.collect{ |project| project.id }.join(',')

    return [] if project_ids.empty?

    msg_conditions = user.member_of_owner? ?
      ["due_date < '#{due_date}' AND completed_on IS NULL AND project_id IN (#{project_ids})"] :
      ["due_date < '#{due_date}' AND completed_on IS NULL AND project_id IN (#{project_ids}) AND is_private = ?", false]

    self.where(msg_conditions)
  end

  # Accesibility

  attr_accessible :name, :description, :due_date, :assigned_to_id, :is_private

  # Validation

  validates_presence_of :name
  validates_each :is_private, :if => Proc.new { |obj| !obj.last_edited_by_owner? } do |record, attr, value|
    record.errors.add(attr, I18n.t('not_allowed')) if value == true
  end

  validates_each :assigned_to, :allow_nil => true do |record, attr, value|
    record.errors.add(attr, I18n.t('not_part_of_project')) if !value.nil? and !value.is_part_of(record.project)
  end
  
  # Indexing
  define_index do
    indexes :name
    indexes :description
    indexes tag_list(:tag), :as => :tags
    
    has :assigned_to_company_id
    has :assigned_to_user_id
    has :project_id
    has :is_private
    has :created_on
    has :updated_on
  end
end
