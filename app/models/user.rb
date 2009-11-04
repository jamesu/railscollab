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

require 'digest/sha1'

class User < ActiveRecord::Base
  include ActionController::UrlWriter

  belongs_to :company
  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'

  has_many :im_values, :order => 'im_type_id DESC', :dependent => :delete_all
  has_many :application_logs, :foreign_key => 'created_by_id', :dependent => :destroy

  has_many :project_milestones, :foreign_key => 'created_by_id', :dependent => :destroy
  has_many :project_tasks,      :foreign_key => 'created_by_id', :dependent => :destroy
  has_many :project_task_lists, :foreign_key => 'created_by_id', :dependent => :destroy
  has_many :project_times,      :foreign_key => 'created_by_id', :dependent => :destroy
  has_many :project_file_revisions,      :foreign_key => 'created_by_id', :dependent => :destroy
  has_many :project_files,      :foreign_key => 'created_by_id', :dependent => :destroy
  has_many :project_messages,   :foreign_key => 'created_by_id', :dependent => :destroy
  has_many :comments,           :foreign_key => 'created_by_id', :dependent => :destroy
  has_many :tags,               :foreign_key => 'created_by_id', :dependent => :destroy

  has_many :project_users,     :dependent => :delete_all
  has_many :projects,          :through => :project_users
  has_many :active_projects,   :through => :project_users, :source => :project, :conditions => 'projects.completed_on IS NULL',     :order => 'projects.priority ASC, projects.name ASC'
  has_many :finished_projects, :through => :project_users, :source => :project, :conditions => 'projects.completed_on IS NOT NULL', :order => 'projects.completed_on DESC'

  has_and_belongs_to_many :subscriptions, :class_name => 'ProjectMessage', :association_foreign_key => 'message_id', :join_table => :message_subscriptions
  
  has_attached_file :avatar, :styles => { :thumb => "50x50" }, :default_url => ''
  
  has_many :assigned_times, :class_name => 'ProjectTime', :foreign_key => 'assigned_to_user_id'

  def twister_array=(value)
    self.twister = value.join()
  end

  def twister_array
    self.twister.split('').map{ |val| val.to_i }
  end

  def im_info
    # Grab all types
    all_types = ImType.all(:select => 'id, name')
    return [] if all_types.empty?

    # Get an id list
    all_type_ids = all_types.collect{ |im_id| im_id.id }

    # Find all values
    values = self.im_values

    # Add the missing values in as blank's
    all_types.each do |type|
      found_type = values.any?{ |value| value.im_type_id == type.id }

      values << ImValue.new(:user => self, :im_type_id => type.id) unless found_type
    end

    values
  end

  def password=(value)
    salt = nil
    token = nil

    if value.empty?
      self.salt = nil
      self.token = nil
      return
    end
    @password = value

    # Calculate a unique token with salt
    loop do
      # Grab a few random things...
      tnow = Time.now()
      sec = tnow.tv_usec
      usec = tnow.tv_usec % 0x100000
      rval = rand()
      roffs = rand(25)

      # Now we can calculate salt and token
      salt = Digest::SHA1.hexdigest(sprintf("%s%08x%05x%.8f", rand(32767), sec, usec, rval))[roffs..roffs+12]
      token = Digest::SHA1.hexdigest(salt + value)

      break if User.first(:conditions => ['token = ?', token]).nil?
    end

    self.salt = salt
    self.token = token

    # Calculate string twist
    calc_twister = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']
    loop do
      calc_twister.sort!{ rand(3) - 1 }
      break if (calc_twister[0] != '0')
    end
    
    self.twister_array = calc_twister
  end
  
  def password_reset_key
    Digest::SHA1.hexdigest(self.salt + self.twisted_token + (self.last_login.nil? ? '' : self.last_login.strftime('%Y-%m-%d %H:%M:%S')))
  end

  def twisted_token
    value = self.token
    return value if value.valid_hash?

    twist_array = self.twister_array
    result = ''
    (0..3).each do |i|
      offs = i*10
      result += value[offs..(offs+9)].twist(twist_array)
    end

    result
  end

  def twisted_token_valid?(value)
    return false unless value.valid_hash?

    begin
      twist_array = self.twister_array
      result = ''
      (0..3).each do |i|
        offs = i*10
        result += value[offs..(offs+9)].untwist(twist_array)
      end
    rescue
      return false
    end

    result == self.token
  end

  def remember?
    remember_expires_at && Time.now.utc < remember_expires_at
  end

  def remember_me!
    self.remember_expires_at = 2.weeks.from_now.utc
    self.remember = Digest::SHA1.hexdigest(salt + remember_expires_at.to_s + token)
    save(false)
  end

  def forget_me!
    self.remember = nil
    self.remember_expires_at = nil
    save(false)
  end

  def self.openid_login(identity_url)
    user = first(:conditions => ['identity_url = ?', identity_url])
    return nil if user.nil?

    now = Time.now.utc
    user.last_login = now
    user.last_activity = now
    user.last_visit = now
    user.save!

    user
  end

  def self.authenticate(login, pass)
    user = first(:conditions => ['username = ?', login])
    return nil if user.nil? or not user.valid_password(pass)

    now = Time.now.utc
    user.last_login = now
    user.last_activity = now
    user.last_visit = now
    user.save!

    user
  end

  def valid_password(pass)
    self.token == Digest::SHA1.hexdigest(self.salt + pass)
  end

  # Core permissions

  def self.can_be_created_by(user)
    user.member_of_owner? and user.is_admin
  end

  def can_be_deleted_by(user)
    return false if self.owner_of_owner? or user.id == self.id
    user.is_admin
  end

  def can_be_viewed_by(user)
    user.member_of_owner? or user.company_id == self.company_id or self.member_of_owner?
  end

  # Specific permissions

  def profile_can_be_updated_by(user)
    (self.id == user.id and !user.is_anonymous?) or (user.member_of_owner? and user.is_admin)
  end

  def permissions_can_be_updated_by(user)
    return false if self.owner_of_owner?
    user.member_of_owner? and user.is_admin
  end

  # Helpers

  def all_milestones
    ProjectMilestone.all_by_user(self)
  end

  def todays_milestones
    ProjectMilestone.todays_by_user(self)
  end

  def late_milestones
    ProjectMilestone.late_by_user(self)
  end

  def member_of_owner?
    !self.is_anonymous? and self.company.is_owner?
  end

  def owner_of_owner?
    self.company.is_owner? and self.company.created_by_id == self.id
  end

  def is_anonymous?
    AppConfig.allow_anonymous and self.username == 'Anonymous'
  end

  def is_part_of(project)
    self.member_of(project)
  end

  def member_of(project)
    return ProjectUser.all(:conditions => ['user_id = ? AND project_id = ?', self.id, project.id]).length > 0
  end

  def has_all_permissions(project, reload=false)
    return false if is_anonymous?
    
    perms = self.permissions_for(project, reload)
    return perms.nil? ? false : (self.is_admin or perms.has_all_permissions?)
  end

  def has_permission(project, pname, reload=false)
    return false if is_anonymous?
    
    perms = self.permissions_for(project, reload)
    return perms.nil? ? false : (self.is_admin or perms[pname])
  end

  def permissions_for(project, reload=false)
    @@cached_permissions ||= {}
    @@cached_permissions[project] = nil if reload
    @@cached_permissions[project] = (ProjectUser.first(:conditions => ['user_id = ? AND project_id = ?', self.id, project.id]) || false)
    
    @@cached_permissions[project].class == FalseClass ? nil : @@cached_permissions[project]
  end

  def has_avatar?
    self.avatar?
  end

  def recent_activity_feed_url(project=nil, format='rss')
    if project.nil?
      return (url_for :only_path => true, :controller => 'feed', :action => 'recent_activities',  :user => self.id, :format => format, :token => self.twisted_token())
    else
      return (url_for :only_path => true, :controller => 'feed', :action => 'project_activities', :user => self.id, :format => format, :token => self.twisted_token(), :project => project.id)
    end
  end

  def milestone_feed_url(project=nil, format='ics')
    if project.nil?
      return (url_for :only_path => true, :controller => 'feed', :action => 'recent_milestones',  :user => self.id, :format => format, :token => self.twisted_token())
    else
      return (url_for :only_path => true, :controller => 'feed', :action => 'project_milestones', :user => self.id, :format => format, :token => self.twisted_token(), :project => project.id)
    end
  end

  def time_export_url(project=nil, format='csv')
    if project.nil?
      return (url_for :only_path => true, :controller => 'feed', :action => 'export_times', :user => self.id, :format => format, :token => '-')
    else
      return (url_for :only_path => true, :controller => 'feed', :action => 'export_times', :user => self.id, :format => format, :token => '-', :project => project.id)
    end
  end

  def avatar_url
    if !avatar?
      "http://gravatar.com/avatar/#{Digest::MD5.hexdigest email}?s=50&d=" + URI.encode("#{AppConfig.site_url}/themes/#{AppConfig.site_theme}/images/avatar.gif")
    else
      avatar.url(:thumb)
    end
  end

  def display_name
    display_name? ? read_attribute(:display_name) : username
  end

  def object_name
    self.display_name
  end

  def object_url(host = nil)
    url_for hash_for_user_path(:only_path => host.nil?, :host => host, :id => self.id)
  end

  def self.get_online(active_in=15)
    datetime = Time.now.utc - (active_in.minutes)
    User.all(:conditions => ['last_activity > ?', datetime], :select => 'id, company_id, username, display_name')
  end

  def self.select_list
    items = [['None', 0]]
    items += self.all.collect{ |user| [user.username, user.id] }
  end

  # Serialization
  alias_method :ar_to_xml, :to_xml
  
  def to_xml(options = {}, &block)
    default_options = {
      :except => [
        :salt,
        :token,
        :twister,
        :last_login,
        :last_visit,
        :last_activity,
        :identity_url
      ]}
    self.ar_to_xml(options.merge(default_options), &block)
  end

  before_create :process_params
  before_update :process_update_params

  def process_params
    write_attribute('last_login',    nil)
    write_attribute('last_activity', nil)
    write_attribute('last_visit',    nil)
  end

  def process_update_params
  end

  def password_required?
    token.blank? || !@password.blank?
  end

  # Accesibility

  attr_accessible :display_name, :email, :time_zone, :title, :office_number, :office_number_ext, :fax_number, :mobile_number, :home_number, :new_account_notification

  attr_accessor :password_confirmation
  attr_reader :password

  # Validation
  
  validates_presence_of :username, :on => :create
  validates_length_of :username, :within => 3..40

  validates_presence_of :password, :if => :password_required?
  validates_length_of :password, :minimum => 4, :if => :password_required?
  validates_confirmation_of :password, :if => :password_required?
  
  validates_uniqueness_of :username
  validates_uniqueness_of :email
  validates_uniqueness_of :identity_url, :if => Proc.new { |user| !(user.identity_url.nil? or user.identity_url.empty? ) }
end
