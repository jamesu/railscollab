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

class Message < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :milestone,        optional: true
  belongs_to :category,         counter_cache:  true, optional: true
  belongs_to :project

  belongs_to :created_by, class_name: 'User', foreign_key:  'created_by_id'
  belongs_to :updated_by, class_name: 'User', foreign_key:  'updated_by_id', optional: true

  has_many :comments, as:  'rel_object', dependent:  :destroy
  #has_many :tags, as:  'rel_object', dependent:  :destroy
  has_many :attached_file, as:  'rel_object'

  has_many :project_file, through:  :attached_file

  has_and_belongs_to_many :subscribers, class_name: 'User', :join_table => 'message_subscriptions', foreign_key:  'message_id'

  scope :is_public, -> { where(:is_private => false) }
  
  scope :important, -> { where(:is_important => true) }

  before_validation :process_params, :on => :create
  after_create  :process_create
  before_update :process_update_params
  before_destroy :process_destroy

  def process_params
    self.comments_enabled = true unless self.created_by.member_of_owner?
  end

  def process_create
    Activity.new_log(self, self.created_by, :add, self.is_private)
  end

  def process_update_params
    Activity.new_log(self, self.updated_by, :edit, self.is_private)
  end

  def process_destroy
    Tag.clear_by_object(self)
    AttachedFile.clear_attachments(self)
    Activity.new_log(self, self.updated_by, :delete, self.is_private)
  end

  def ordered_comments
    self.comments.order('created_on ASC')
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

  def object_name
    self.title
  end

  def object_url(host = nil)
    project_message_url(self.project, self, only_path: true, host: host)
  end

  def attached_files(with_private)
    if with_private
      project_file
    else
      project_file.where(:is_private => false)
    end
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
      MailNotifier.message_comment(subscriber, comment, self).deliver_now
    end
  end

  def last_edited_by_owner?
    self.created_by.member_of_owner? or (!self.updated_by.nil? and self.updated_by.member_of_owner?)
  end

  def send_notification(user)
    MailNotifier.new_message(user, self).deliver_now
  end

  # Accesibility

  #attr_accessible :title, :text, :milestone_id, :category_id, :is_private, :is_important, :comments_enabled, :anonymous_comments_enabled

  # Validation

  validates_presence_of :title
  validates_presence_of :text
  validates_each :milestone, :allow_nil => true do |record, attr, value|
    record.errors.add(attr, I18n.t('not_part_of_project')) if value.project_id != record.project_id
  end

  validates_each :category do |record, attr, value|
    record.errors.add(attr, I18n.t('not_part_of_project')) if value && value.project_id != record.project_id
  end

  validates_each :is_private, :is_important, :anonymous_comments_enabled, :if => Proc.new { |obj| !obj.last_edited_by_owner? } do |record, attr, value|
    record.errors.add(attr, I18n.t('not_allowed')) if value == true
  end

  validates_each :comments_enabled, :if => Proc.new { |obj| !obj.last_edited_by_owner? } do |record, attr, value|
    record.errors.add(attr, I18n.t('not_allowed')) if value == false
  end
  
  # Indexing
  define_index do
    indexes :title
    indexes :text
    indexes tag_list(:tag), as:  :tags
    
    has :project_id
    has :category_id
    has :is_private
    has :created_on
    has :updated_on
  end
end
