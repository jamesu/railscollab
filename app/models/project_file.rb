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

class ProjectFile < ActiveRecord::Base
  include Rails.application.routes.url_helpers

  belongs_to :project
  belongs_to :folder, :counter_cache => true

  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
  belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'

  has_many :project_file_revisions, :foreign_key => 'file_id', :order => 'revision_number DESC', :dependent => :destroy
  has_many :attached_files, :foreign_key => 'file_id'
  has_many :comments, :as => 'rel_object', :dependent => :destroy do
    def public(reload=false)
      # Grab public comments only
      @public_comments = nil if reload
      @public_comments ||= all(:conditions => ['is_private = ?', false])
    end
  end
  #has_many :tags, :as => 'rel_object', :dependent => :destroy

  before_validation :process_params, :on => :create
  after_create  :process_create
  before_update :process_update_params
  before_destroy :process_destroy

  def process_params
    write_attribute('comments_enabled', true) unless self.created_by.member_of_owner?
  end

  def process_create
    Activity::new_log(self, self.created_by, :add)
  end

  def process_update_params
    Activity::new_log(self, self.updated_by, :edit)
  end

  def process_destroy
    AttachedFile.clear_files(self.id)
    Tag.clear_by_object(self)
    Activity::new_log(self, self.updated_by, :delete)
  end

  def tags
    Tag.list_by_object(self).join(',')
  end

  def tags_with_spaces
    Tag.list_by_object(self).join(' ')
  end

  def tags=(val)
    Tag.clear_by_object(self)
    real_owner = project_file_revisions.empty? ? nil : self.project_file_revisions[0].created_by
    Tag.set_to_object(self, val.split(','), real_owner) unless val.nil?
  end

  def last_created_by
    project_file_revisions[0].created_by
  end

  def last_updated_by
    project_file_revisions[0].updated_by
  end

  def object_name
    self.filename
  end

  def object_url(host = nil)
    url_for hash_for_file_path(:only_path => true, :host => host, :id => self.id, :active_project => self.project_id)
  end

  def download_url
    url_for hash_for_download_file_path(:only_path => true, :id => self.id, :active_project => self.project_id)
  end

  def filetype_icon_url
    project_file_revisions.empty? ? "/assets/filetypes/unknown.png" : project_file_revisions[0].filetype_icon_url
  end

  def file_size
    project_file_revisions.empty? ? 0 : project_file_revisions[0].filesize
  end

  def last_revision
    self.project_file_revisions[0]
  end

  def last_edited_by_owner?
    self.created_by.member_of_owner? or (!self.updated_by.nil? and self.updated_by.member_of_owner?)
  end

  def send_comment_notifications(comment)
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

  def add_revision(file, new_revision, user, comment)
    file_revision = ProjectFileRevision.new(:revision_number => new_revision)
    file_revision.project_file = self
    file_revision.upload_file = file
    file_revision.created_by = user
    file_revision.comment = comment
    file_revision.save!
    
    Activity::new_log(file_revision, user, :add, self.is_private, self.project) unless new_revision == 1
  end

  def update_revision(file, old_revision, user, comment)
    old_revision.upload_file = file
    old_revision.updated_by = user
    old_revision.comment = comment
    old_revision.save!
  end

  def self.handle_files(files, to_object, user, is_private)
    return 0 if files.nil?
    
    count = 0
    files.each do |file|
      if !file.respond_to?(:original_filename)
        count += 1
        next
      end

      filename = file.original_filename.sanitize_filename
      
      ProjectFile.transaction do
        attached_file = ProjectFile.new()
        attached_file.filename = filename
        attached_file.is_private = is_private
        attached_file.is_visible = false
        attached_file.expiration_time = Time.now.utc
        attached_file.project = to_object.project
        attached_file.created_by = user

        if attached_file.save
          # Upload revision
          attached_file.add_revision(file, 1, user, '')
          
          # Attach to object
          AttachedFile.create!(:created_on => attached_file.created_on, 
                               :created_by => user, 
                               :rel_object => to_object, 
                               :project_file => attached_file)
          #to_object.project_file << attached_file

          count += 1
        end
      end
    end

    return count
  end

  def self.find_grouped(group_field, params)
    grouped_fields = {}
    found_files = ProjectFile.where(params[:conditions])
    found_files = found_files.paginate(:page => params[:page], :per_page => params[:per_page]) unless params[:page].nil?
    found_files = found_files.order(params[:order]) unless params[:order].nil?
    
    @pagination = []

    group_type = DateTime if ['created_on', 'updated_on'].include?(group_field)
    group_type ||= String

    grouped_fields = found_files.group_by do |file|
      dest_str = nil

      if group_type == DateTime
        file_time = file[group_field]
        dest_str = file_time
      else
        dest_str = file[group_field].to_s[0..0]
      end

      dest_str
    end

    return found_files, grouped_fields
  end

  # Accesibility

  attr_accessible :folder_id, :description, :is_private, :is_important, :comments_enabled, :anonymous_comments_enabled

  # Validation

  validates_presence_of :filename
  validates_each :folder, :allow_nil => true do |record, attr, value|
    record.errors.add(attr, I18n.t('not_part_of_project')) if value.project_id != record.project_id
  end

  validates_each :is_private, :is_important, :anonymous_comments_enabled, :if => Proc.new { |obj| !obj.last_edited_by_owner? } do |record, attr, value|
    record.errors.add(attr, I18n.t('not_allowed')) if value == true
  end

  validates_each :comments_enabled, :if => Proc.new { |obj| !obj.last_edited_by_owner? } do |record, attr, value|
    record.errors.add(attr, I18n.t('not_allowed')) if value == false
  end
end
