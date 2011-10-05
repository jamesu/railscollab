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

require 'digest/sha1'

class User < ActiveRecord::Base
  include Rails.application.routes.url_helpers
  include Authentication
  include Authentication::ByCookieToken

  belongs_to :company
  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'

  has_many :im_values, :order => 'im_type_id DESC', :dependent => :delete_all
  has_many :activities, :foreign_key => 'created_by_id', :dependent => :destroy

  has_many :milestones, :foreign_key => 'created_by_id', :dependent => :destroy
  has_many :tasks,      :foreign_key => 'created_by_id', :dependent => :destroy
  has_many :task_lists, :foreign_key => 'created_by_id', :dependent => :destroy
  has_many :time_records,           :foreign_key => 'created_by_id', :dependent => :destroy
  has_many :project_file_revisions, :foreign_key => 'created_by_id', :dependent => :destroy
  has_many :project_files,      :foreign_key => 'created_by_id', :dependent => :destroy
  has_many :messages,           :foreign_key => 'created_by_id', :dependent => :destroy
  has_many :comments,           :foreign_key => 'created_by_id', :dependent => :destroy
  has_many :tags,               :foreign_key => 'created_by_id', :dependent => :destroy

  has_many :people,            :dependent => :delete_all
  has_many :projects,          :through => :people
  has_many :active_projects,   :through => :people, :source => :project, :conditions => 'projects.completed_on IS NULL',     :order => 'projects.priority ASC, projects.name ASC'
  has_many :finished_projects, :through => :people, :source => :project, :conditions => 'projects.completed_on IS NOT NULL', :order => 'projects.completed_on DESC'

  has_and_belongs_to_many :subscriptions, :class_name => 'Message', :association_foreign_key => 'message_id', :join_table => :message_subscriptions

  has_attached_file :avatar,
    :styles => { :thumb => "50x50" },
    :default_url => '',
    :path => Rails.configuration.attach_to_s3 ?
      "avatar/:id/:style.:extension" :
      ":rails_root/public/system/:attachment/:id/:style/:filename"

  has_many :assigned_times, :class_name => 'TimeRecord', :foreign_key => 'assigned_to_user_id'

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

      break if User.where({:token => token}).first.nil?
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

  def self.authenticate(login, pass)
    user = User.where(:username => login).first
    if (!user.nil?) and (user.valid_password(pass))
      now = Time.now.utc
      user.last_login = now
      user.last_activity = now
      user.last_visit = now
      user.save!
      return user
    else
      return nil
    end
  end

  def valid_password(pass)
    self.token == Digest::SHA1.hexdigest(self.salt + pass)
  end

  # Helpers

  def all_milestones
    Milestone.all_by_user(self)
  end

  def todays_milestones
    Milestone.todays_by_user(self)
  end

  def late_milestones
    Milestone.late_by_user(self)
  end

  def member_of_owner?
    !self.is_anonymous? and self.company.is_owner?
  end

  def owner_of_owner?
    self.company.is_owner? and self.company.created_by_id == self.id
  end

  def is_anonymous?
    Rails.configuration.allow_anonymous and self.username == 'Anonymous'
  end

  def is_part_of(project)
    self.member_of(project)
  end

  def member_of(project)
    Person.where(:user_id => id, :project_id => project.id).length > 0
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
    @@cached_permissions[project] = (Person.first(:conditions => ['user_id = ? AND project_id = ?', self.id, project.id]) || false)
    
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
      return (url_for :only_path => true, :controller => 'feed', :action => 'milestones', :user => self.id, :format => format, :token => self.twisted_token(), :project => project.id)
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
      "http://gravatar.com/avatar/#{Digest::MD5.hexdigest email}?s=50&d=" + URI.encode("#{Rails.configuration.site_url}/assets/avatar.gif")
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
    User.where(['last_activity > ?', datetime]).select('id, company_id, username, display_name')
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
        :last_activity
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
end
