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

class ProjectMessage < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  belongs_to :project_milestone,        :foreign_key => 'milestone_id'
  belongs_to :project_message_category, :foreign_key => 'category_id', :counter_cache => true
  belongs_to :project

  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
  belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'

  has_many :comments, :as => 'rel_object', :order => 'created_on ASC', :dependent => :destroy do
    def public(reload=false)
      # Grab public comments only
      @public_comments = nil if reload
      @public_comments ||= all(:conditions => ['is_private = ?', false])
    end
  end
  #has_many :tags, :as => 'rel_object', :dependent => :destroy
  has_many :attached_file, :as => 'rel_object'

  has_many :project_file, :through => :attached_file

  has_and_belongs_to_many :subscribers, :class_name => 'User', :join_table => 'message_subscriptions', :foreign_key => 'message_id'

  before_validation :process_params, :on => :create
  after_create  :process_create
  before_update :process_update_params
  before_destroy :process_destroy

  def process_params
    self.comments_enabled = true unless self.created_by.member_of_owner?
  end

  def process_create
    ApplicationLog.new_log(self, self.created_by, :add, self.is_private)
  end

  def process_update_params
    ApplicationLog.new_log(self, self.updated_by, :edit, self.is_private)
  end

  def process_destroy
    Tag.clear_by_object(self)
    AttachedFile.clear_attachments(self)
    ApplicationLog.new_log(self, self.updated_by, :delete, self.is_private)
  end

  def tags
    Tag.list_by_object(self).join(',')
  end

  def tags_with_spaces
    Tag.list_by_object(self).join(' ')
  end

  def tags=(val)
    Tag.clear_by_object(self)
    Tag.set_to_object(self, val.split(',')) unless val.nil?
  end

  def object_name
    self.title
  end

  def object_url(host = nil)
    url_for hash_for_message_path(:id => self.id, :active_project => self.project_id, :only_path => host.nil?, :host => host)
  end

  def attached_files(with_private)
    self.project_file
  end

  def ensure_subscribed(user)
    return if user.is_anonymous?

    begin
      self.subscribers.find(user.id)
    rescue ActiveRecord::RecordNotFound
      self.subscribers << user
    end
  end

  def send_comment_notifications(comment)
    self.subscribers.each do |subscriber|
      next if subscriber == comment.created_by
      Notifier.deliver_message_comment(subscriber, comment, self)
    end
  end

  def last_edited_by_owner?
    self.created_by.member_of_owner? or (!self.updated_by.nil? and self.updated_by.member_of_owner?)
  end

  def send_notification(user)
    Notifier.deliver_message(user, self)
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

  # Accesibility

  attr_accessible :title, :text, :additional_text, :milestone_id, :category_id, :is_private, :is_important, :comments_enabled, :anonymous_comments_enabled

  # Validation

  validates_presence_of :title
  validates_presence_of :text
  validates_each :project_milestone, :allow_nil => true do |record, attr, value|
    record.errors.add(attr, :not_part_of_project.l) if value.project_id != record.project_id
  end

  validates_each :project_message_category do |record, attr, value|
    record.errors.add(attr, :not_part_of_project.l) if value && value.project_id != record.project_id
  end

  validates_each :is_private, :is_important, :anonymous_comments_enabled, :if => Proc.new { |obj| !obj.last_edited_by_owner? } do |record, attr, value|
    record.errors.add(attr, :not_allowed.l) if value == true
  end

  validates_each :comments_enabled, :if => Proc.new { |obj| !obj.last_edited_by_owner? } do |record, attr, value|
    record.errors.add(attr, :not_allowed.l) if value == false
  end
end
