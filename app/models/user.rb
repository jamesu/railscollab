=begin
RailsCollab
-----------

Copyright (C) 2007 - 2008 James S Urquhart (jamesu at gmail.com)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
=end

require 'digest/sha1'
require 'gd2' unless AppConfig.no_gd2

class User < ActiveRecord::Base
	include ActionController::UrlWriter
  
	belongs_to :company
	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
	
	has_many :im_values, :order => 'im_type_id DESC'

	has_many :project_milestones, :foreign_key => 'assigned_to_user_id'
	has_many :project_tasks, :foreign_key => 'assigned_to_user_id'
	has_many :project_times, :foreign_key => 'assigned_to_user_id'
	
	has_many :project_users
	has_many :projects, :through => :project_users
	has_many :active_projects, :through => :project_users, :source => :project, :conditions => 'projects.completed_on IS NULL', :order => 'projects.priority ASC'
	has_many :finished_projects, :through => :project_users, :source => :project, :conditions => 'projects.completed_on IS NOT NULL', :order => 'projects.completed_on DESC'
	
	has_and_belongs_to_many :subscriptions, :class_name => 'ProjectMessage', :association_foreign_key => 'message_id', :join_table => :message_subscriptions
	
	
	before_destroy :process_destroy
	
	def process_destroy
		# Explicitly remove these
		ActiveRecord::Base.connection.execute("DELETE FROM project_users WHERE user_id = #{self.id}")
		ActiveRecord::Base.connection.execute("DELETE FROM user_im_values WHERE user_id = #{self.id}")
		
		FileRepo.handle_delete(self.avatar_file) unless self.avatar_file.nil?
	end
	
	def twister_array=(value)
		self.twister = value.join()
	end
	
	def twister_array()
		return self.twister.split('').map do |val|
			val.to_i
		end
	end
	
	def im_info
		# Grab all types
		all_types = ImType.find(:all, :select => 'id, name')
		if all_types.length == 0
			return []
		end
		
		# Get an id list
		all_type_ids = all_types.collect do |im_id|
			im_id.id
		end.join ','
		
		# Find all values
		found_values = ImValue.find(:all, :conditions => "user_id = #{self.id} AND im_type_id IN (#{all_type_ids})")
		all_values = found_values.collect do |val|
			val
		end
		
		# Add the missing values in as blank's
		all_types.each do |check_type|
			found_type = false
			all_values.each do |check_value|
				if check_value.im_type_id == check_type.id
					found_type = true
					break
				end
			end
			
			if not found_type then
				all_values << ImValue.new(:user => self, :im_type_id => check_type.id)
			end
		end
		
		return all_values
	end
	
	def password=(value)
		salt = nil
		token = nil
		
		if value.empty?
			self.salt = nil
			self.token = nil
			return
		end
		
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
			
			break if User.find(:first, :conditions => ["token = ?", token]).nil?
		end
		
		self.salt = salt
		self.token = token
		
		# Calculate string twist
		calc_twister = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']
		loop do
			calc_twister.sort! { rand(3)-1 }
			break if (calc_twister[0] != '0')
		end
		
		self.twister_array = calc_twister
	end
	
	def password
		return self.token
	end
	
	def password_reset_key
	   Digest::SHA1.hexdigest(self.salt + self.twisted_token + (self.last_login.nil? ? '' : self.last_login.strftime('%Y-%m-%d %H:%M:%S')))
	end
	
	def twisted_token()
		value = self.token
		return value if not value.valid_hash?
		
		twist_array = self.twister_array
		result = ''
		(0..3).each do |i|
			offs = i*10
			result += value[offs..(offs+9)].twist(twist_array)
		end
		
    	return result
	end
	
	def twisted_token_valid?(value)
		return false if not value.valid_hash?
		
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
		
		return result == self.token
	end
	
	def self.openid_login(identity_url)
		user = find(:first, :conditions => ["identity_url = ?", identity_url])
		if (!user.nil?)
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
	
	def self.authenticate(login, pass)
		user = find(:first, :conditions => ["username = ?", login])
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
		return self.token == Digest::SHA1.hexdigest(self.salt + pass)
	end
	
	def send_password_reset()
		Notifier.deliver_password_reset(self)
	end
	
	def send_new_account_info(password=nil)
		Notifier.deliver_account_new_info(self, password)
	end
	
	# Core permissions
	
	def self.can_be_created_by(user)
		return (user.member_of_owner? and user.is_admin)
	end
	
	def can_be_deleted_by(user)
		return false if (self.owner_of_owner? or user.id == self.id)
		return user.is_admin
	end
	
	def can_be_viewed_by(user)
		return (user.member_of_owner? or user.company_id == self.id or self.member_of_owner?)
	end
	
	# Specific permissions
	
    def profile_can_be_updated_by(user)
      return ((self.id == user.id and !user.is_anonymous?) or (user.member_of_owner? and user.is_admin))
    end
    
    def permissions_can_be_updated_by(user)
      return false if self.owner_of_owner?
      return (user.member_of_owner? and user.is_admin)
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
		!self.is_anonymous? and self.company.client_of.nil?
	end
	
	def owner_of_owner?
		self.company.client_of.nil? and self.company.created_by.id == self.id
	end
	
	def is_anonymous?
	   AppConfig.allow_anonymous and self.username == 'Anonymous'
	end
	
	def is_part_of(project)
	   self.member_of(project)
	end
	
	def member_of(project)
	 return ProjectUser.find(:all, :conditions => ["user_id = ? AND project_id = ?", self.id, project.id]).length > 0
	end
	
	def has_all_permissions(project)
	 return false if is_anonymous?
	 @@cached_permissions ||= self.permissions_for(project)
	 return @@cached_permissions.nil? ? false : (self.is_admin or @@cached_permissions.has_all_permissions?)
	end
	
	def has_permission(project, pname)
	 return false if is_anonymous?
	 @@cached_permissions ||= self.permissions_for(project)
	 return @@cached_permissions.nil? ? false : (self.is_admin or @@cached_permissions[pname])
	end
	
	def permissions_for(project)
	 perms = ProjectUser.find(:first, :conditions => ['user_id = ? AND project_id = ?', self.id, project.id])
	 return perms ? perms : nil
	end
	
	def has_avatar?
	    !self.avatar_file.nil?
	end
	
	def recent_activity_feed_url(project=nil, format='rss')
		if not project.nil?
			return (url_for :only_path => true, :controller => 'feed', :action => 'project_activities', :user => self.id, :project => project.id, :format => format, :token => self.twisted_token())
		else
			return (url_for :only_path => true, :controller => 'feed', :action => 'recent_activities', :user => self.id, :format => format, :token => self.twisted_token())
		end
	end
	
	def milestone_feed_url(project=nil, format='ics')
		if not project.nil?
			return (url_for :only_path => true, :controller => 'feed', :action => 'project_milestones', :user => self.id, :project => project.id, :format => format, :token => self.twisted_token())
		else
			return (url_for :only_path => true, :controller => 'feed', :action => 'recent_milestones', :user => self.id, :format => format, :token => self.twisted_token())
		end
	end
	
	def time_export_url(project=nil, format='csv')
		if not project.nil?
			return (url_for :only_path => true, :controller => 'feed', :action => 'export_times', :user => self.id, :project => project.id, :format => format, :token => '-')
		else
			return (url_for :only_path => true, :controller => 'feed', :action => 'export_times', :user => self.id, :format => format, :token => '-')
		end
	end
	
	def avatar
		nil
	end
	
	def avatar=(value)
		return if AppConfig.no_gd2
		FileRepo.handle_delete(self.avatar_file) unless self.avatar_file.nil?
		
		if value.nil?
			self.avatar_file = nil
			return
		end
		
		content_type = value.content_type.chomp
		
		unless ['image/jpg', 'image/jpeg', 'image/gif', 'image/png'].include?(content_type)
			self.errors.add(:avatar, "Unsupported format")
			return
		end
		
		max_width = AppConfig.max_avatar_width
		max_height = AppConfig.max_avatar_height
		
		begin
			data = value.read
			image = GD2::Image.load(data)
			image.resize!(image.width > max_width ? max_width : image.width,
			              image.height > max_height ? max_height : image.height)
		rescue
			self.errors.add(:avatar, "Invalid data")
			return
		end
		
		self.avatar_file = FileRepo.handle_storage(image.png, "avatar_#{self.id}.png", 'image/png')
	end
	
	def avatar_url
	   unless FileRepo.no_s3? or self.avatar_file.nil?
	       dat = FileRepo.get_data(self.avatar_file)
	       if !dat.nil?
	           avatar = (dat.class == Hash) ? dat[:url] : self.avatar_file
	       else
	           avatar = nil
	       end
	   else
	       avatar = self.avatar_file
	   end
	   
	   if avatar.nil? 
		  "/themes/#{AppConfig.site_theme}/images/avatar.gif"
	   else
		  "/account/avatar/#{self.id}.png"
	   end
	end
	
	def object_name
		self.display_name
	end
	
	def object_url
		url_for :only_path => true, :controller => 'user', :action => 'card', :id => self.id
	end
	
	def self.get_online(active_in=15)
	  datetime = Time.now.utc
	  datetime -= (active_in * 60)
	  
	  User.find(:all, :conditions => "last_activity > '#{datetime.strftime('%Y-%m-%d %H:%M:%S')}'", :select => "id, company_id, username, display_name")
	end
	
	def self.select_list
	   items = self.find(:all).collect do |user|
	     [user.username, user.id]
	   end
	   
	   items = [["None", 0]] + items
	end
	    
	protected
	    
	before_create :process_params
	before_update :process_update_params
	 
	def process_params
		write_attribute("last_login", nil)
		write_attribute("last_activity", nil)
		write_attribute("last_visit", nil)
	end
	
	def process_update_params
	end
	
	# Accesibility
	
	attr_accessible :display_name, :email, :time_zone, :title, :office_number, :office_number_ext, :fax_number, :mobile_number, :home_number, :new_account_notification
	
	# Validation
	
	validates_length_of :username, :within => 3..40
	validates_presence_of :username, :password
	validates_uniqueness_of :username, :on => :create
	validates_uniqueness_of :email
	validates_uniqueness_of :identity_url, :if => Proc.new { |user| !(user.identity_url.nil? or user.identity_url.empty? ) }
	#validates_confirmation_of :password, :on => :create  
end
