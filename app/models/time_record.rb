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

class TimeRecord < ApplicationRecord
  include Rails.application.routes.url_helpers
  
  belongs_to :project
  
  belongs_to :company, foreign_key:  'assigned_to_company_id'
  belongs_to :user, foreign_key:  'assigned_to_user_id'
  
  belongs_to :task_list
  belongs_to :task
  
  belongs_to :created_by, class_name: 'User', foreign_key:  'created_by_id'
  belongs_to :updated_by, class_name: 'User', foreign_key:  'updated_by_id'
  
  has_many :messages
  
  #has_many :tags, as:  'rel_object', dependent:  :destroy
  
  scope :running, -> { where('start_date IS NOT NULL AND done_date IS NULL') }
  scope :is_public, -> { where(:is_private => false) }

  before_validation :process_params, :on => :create
  after_create   :process_create
  before_update  :process_update_params
  before_destroy :process_destroy

  def running?
    self.done_date.nil? && !self.start_date.nil?
  end

  def hours
    if self.running?
      ((Time.now - self.start_date) / 3600.0).round(2)
    else
      self[:hours]
    end
  end
   
  def process_params
    if self.assigned_to_user_id.nil?
     write_attribute("assigned_to_user_id", 0)
    end
    if self.assigned_to_company_id.nil?
      write_attribute("assigned_to_company_id", 0)
    end
    
    # set name to task name
    if (self.name.nil? or self.name.blank?) and !self.task.nil?
      self.name = self.task.text[0, TimeRecord.columns_hash['name'].limit]
    end
  end
  
  def process_create
    Activity.new_log(self, self.created_by, :add, self.is_private)
  end
  
  def process_update_params
    if self.assigned_to_user_id.nil?
      write_attribute("assigned_to_user_id", 0)
    end
    if self.assigned_to_company_id.nil?
      write_attribute("assigned_to_company_id", 0)
    end
    
    Activity.new_log(self, self.updated_by, :edit, self.is_private)
  end
  
  def process_destroy
    Tag.clear_by_object(self)
    Activity.new_log(self, self.updated_by, :delete, self.is_private)
  end
  
  def object_name
    self.name
  end
  
  def object_url(host = nil)
    url_for hash_for_time_path(:only_path => host.nil?, :host => host, :id => self.id, :active_project => self.project_id)
  end
  
  # Responsible party assignment
  
  def open_task=(obj)
    self.task_list = obj.try(:task_list)
    self.task = obj
  end
  
  def open_task
    self.task
  end
  
  def open_task_id=(val)
    # Set open_task accordingly
    if (val.nil? || val == '0')
      self.open_task = nil
      return
    end
    
    self.open_task = Task.find(val)
  end
  
  def open_task_id
    if !self.task.nil?
      self.task.id.to_s
    else
      "0"
    end
  end
  
  # Task list / task assignment
  
  def assigned_to=(obj)
    self.company = obj.class == Company ? obj : nil
    self.user = obj.class == User ? obj : nil
  end
  
  def assigned_to
    if self.company
      self.company
    elsif self.user
      self.user
    else
      nil
    end
  end
  
  def assigned_to_id=(val)
    # Set assigned_to accordingly
    if (val.nil? or val == '0' or val == 'c0')
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
    if self.company
      "c#{self.company.id}"
    elsif self.user
      self.user.id.to_s
    else
      "0"
    end
  end
  
  def tags
   return Tag.list_by_object(self).join(',')
  end
  
  def tags_with_spaces
   return Tag.list_by_object(self).join(' ')
  end

  def tag_list
    Tag.where(['rel_object_type = ? AND rel_object_id = ?', object.class.to_s, object.id])
  end
  
  def tags=(val)
   Tag.clear_by_object(self)
   Tag.set_to_object(self, val.split(',')) unless val.nil?
  end
  
  def is_today?
    return self.done_date.to_date == Date.today
  end
  
  def is_yesterday?
    return self.done_date.to_date == Date.today-1
  end
  
  def last_edited_by_owner?
   return (self.created_by.member_of_owner? or (!self.updated_by.nil? and self.updated_by.member_of_owner?))
  end
  
  def self.find_by_task_lists(task_lists, time_conds)
    lists = []

    task_lists.all(:include => {:tasks => :time_records}).each do |list|
      tasks = []
      list.tasks.each do |task|
        times = task.time_records.select do |time|
          time_conds.all? {|attr, value| time.send(attr) == value}
        end
        total = times.inject(0) {|sum, time| sum + time.hours}
        if (total > 0)
          total_billable = times.select(&:is_billable).inject(0) {|sum, time| sum + time.hours}
          extra_conditions = time_conds.clone.merge({'task_list_id' => list.id, 'task_id' => task.id})
          tasks << {:task => task, :hours => total, :billable_hours => total_billable || 0, :times => times}
        end
      end

      lists << {:list => list, :tasks => tasks}
    end

    return lists
  end
  
  def self.find_grouped(group_field, params)
    grouped_fields = {}
    found_times = TimeRecord.where(params[:conditions])
    found_times = found_times.paginate(:page => params[:page], :per_page => params[:per_page]) unless params[:page].nil?
    found_times = found_times.order(params[:order]) unless params[:order].nil?
    
    group_type = TimeRecord if ['assigned_to','project','project_task','project_task_list'].include?(group_field)
    group_type ||= String
    
    found_times.each do |time|
      dest_str = nil
      
      if group_type == TimeRecord
        dest_str = time[group_field].object_name
      else
        dest_str = time[group_field].to_s[0..0]
      end
      
      grouped_fields[dest_str] ||= []
      grouped_fields[dest_str] << file
    end
    
    return found_times, grouped_fields
  end
  
  def self.all_by_user(user)
    project_ids = user.active_project_ids
    
    time_conditions = {:project_id => project_ids}
    time_conditions[:is_private] = false if !user.member_of_owner?
    
    return where(time_conditions)
  end
  
  # Accesibility
  
  #attr_accessible :name, :description, :done_date, :hours, :open_task_id, :assigned_to_id, :is_private, :is_billable
  
  # Validation
  
  validates_presence_of :name
  validates_each :is_private, :if => Proc.new { |obj| !obj.last_edited_by_owner? } do |record, attr, value|
    record.errors.add attr, I18n.t('not_allowed') if value == true
  end
  
  validates_each :assigned_to, :allow_nil => true do |record, attr, value|
    record.errors.add attr, I18n.t('not_part_of_project') if (!value.nil? and !value.is_part_of(record.project))
  end
  
  # Indexing
  define_index do
    indexes :name
    indexes :description
    indexes tag_list(:tag), as:  :tags
    
    has :assigned_to_company_id
    has :assigned_to_user_id
    has :task_list_id
    has :task_id
    has :project_id
    has :is_private
    has :created_on
    has :updated_on
  end
end

