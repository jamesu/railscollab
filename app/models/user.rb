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

require "bcrypt"

class User < ApplicationRecord
  include Rails.application.routes.url_helpers
  include Authentication
  include Authentication::ByCookieToken

  belongs_to :company
  belongs_to :created_by, class_name: "User", foreign_key: "created_by_id", optional: true

  has_many :activities, foreign_key: "created_by_id", dependent: :destroy

  has_many :milestones, foreign_key: "created_by_id", dependent: :destroy
  has_many :tasks, foreign_key: "created_by_id", dependent: :destroy
  has_many :task_lists, foreign_key: "created_by_id", dependent: :destroy
  has_many :time_records, foreign_key: "created_by_id", dependent: :destroy
  has_many :project_file_revisions, foreign_key: "created_by_id", dependent: :destroy
  has_many :project_files, foreign_key: "created_by_id", dependent: :destroy
  has_many :messages, foreign_key: "created_by_id", dependent: :destroy
  has_many :comments, foreign_key: "created_by_id", dependent: :destroy
  has_many :tags, foreign_key: "created_by_id", dependent: :destroy

  has_many :people, dependent: :delete_all
  has_many :projects, through: :people

  has_and_belongs_to_many :subscriptions, class_name: "Message", association_foreign_key: "message_id", join_table: :message_subscriptions

  has_one_attached :avatar do |attachable|
    attachable.variant :thumb, resize_to_limit: [50, 50]
  end

  has_many :assigned_times, class_name: "TimeRecord", foreign_key: "assigned_to_user_id"

  attr_accessor :new_account_notification

  def active_projects
    self.projects.where("projects.completed_on IS NULL")
  end

  def finished_projects
    self.projects.where("projects.completed_on IS NOT NULL")
  end

  def ordered_active_projects
    self.active_projects.order("projects.priority ASC, projects.name ASC")
  end

  def ordered_finished_projects
    self.finished_projects.order("projects.completed_on DESC")
  end

  def twister_array=(value)
    self.twister = value.join()
  end

  def twister_array
    self.twister.split("").map { |val| val.to_i }
  end

  def generate_password
    @generated_password || false
  end

  def generate_password=(value)
    return if value.nil? or value == false
    self.password = self.password_confirmation = Base64.encode64(Digest::SHA1.digest("#{rand(1 << 64)}/#{Time.now.to_f}/#{self.username}"))[0..7]
    @generated_password = true
  end

  def password_confirmation
    @password_confirmation
  end

  def password_confirmation=(value)
    return if @generated_password
    @password_confirmation = value
  end

  def password
    @password
  end

  def password=(value)
    return if @generated_password
    salt = ""
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
      token = BCrypt::Password.create(value)
      break if User.where({ token: token }).first.nil?
    end

    self.salt = salt
    self.token = token

    # Calculate string twist
    calc_twister = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
    loop do
      calc_twister.sort! { rand(3) - 1 }
      break if (calc_twister[0] != "0")
    end

    self.twister_array = calc_twister
  end

  def password_reset_key
    Digest::SHA1.hexdigest(self.salt + self.twisted_token + (self.last_login.nil? ? "" : self.last_login.strftime("%Y-%m-%d %H:%M:%S")))
  end

  def twisted_token
    value = self.token
    return value if value.valid_hash?

    twist_array = self.twister_array
    result = ""
    (0..3).each do |i|
      offs = i * 10
      result += value[offs..(offs + 9)].twist(twist_array)
    end

    result
  end

  def twisted_token_valid?(value)
    return false unless value.valid_hash?

    begin
      twist_array = self.twister_array
      result = ""
      (0..3).each do |i|
        offs = i * 10
        result += value[offs..(offs + 9)].untwist(twist_array)
      end
    rescue
      return false
    end

    result == self.token
  end

  def self.authenticate(login, pass)
    user = User.where(username: login).first
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
    BCrypt::Password.new(self.token) == pass
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
    self.company.is_instance_owner?
  end

  def owner_of_owner?
    self.company.is_instance_owner? and self.company.created_by_id == self.id
  end

  def is_part_of(project)
    self.member_of(project)
  end

  def member_of(project)
    Person.where(user_id: id, project_id: project.id).length > 0
  end

  def permissions_for(project)
    people.where(project_id: project.id).first
  end

  def has_avatar?
    self.avatar.attached?
  end

  def recent_activity_feed_url(project = nil, format = "rss")
    if project.nil?
      return feed_recent_activities_path(user: self.id, format: format, token: self.twisted_token())
    else
      return feed_project_activities_path(user: self.id, project_id: project.id, format: format, token: self.twisted_token())
    end
  end

  def milestone_feed_url(project = nil, format = "ics")
    if project.nil?
      return feed_recent_milestones_path(user: self.id, format: format, token: self.twisted_token())
    else
      return feed_milestones_path(user: self.id, project_id: project.id, format: format, token: self.twisted_token())
    end
  end

  def time_export_url(project = nil, format = "csv")
    if project.nil?
      return feed_export_times_path(user: self.id, format: format, token: self.twisted_token())
    else
      return feed_export_times_path(user: self.id, project_id: project.id, format: format, token: self.twisted_token())
    end
  end

  def avatar_url
    if !avatar.attached?
      "/assets/avatar.gif"
    else
      url_for avatar.variant(:thumb)
    end
  end

  def display_name
    (super() || "").empty? ? self.username : super()
  end

  def object_name
    self.display_name
  end

  def object_url(host = nil)
    user_url(self, only_path: host.nil?, host: host)
  end

  def self.get_online(active_in = 15)
    datetime = Time.now.utc - (active_in.minutes)
    User.where(["last_activity > ?", datetime]).select("id, company_id, username, display_name")
  end

  def self.select_list
    items = [["None", 0]]
    items += self.all.collect { |user| [user.username, user.id] }
  end

  # Serialization

  def to_xml(options = {}, &block)
    default_options = {
      except: [
        :salt,
        :token,
        :twister,
        :last_login,
        :last_visit,
        :last_activity,
      ],
    }
    super(options.merge(default_options), &block)
  end

  before_create :process_params
  before_update :process_update_params

  def process_params
    write_attribute("last_login", nil)
    write_attribute("last_activity", nil)
    write_attribute("last_visit", nil)
  end

  def process_update_params
  end

  def password_required?
    token.blank? || !@password.blank?
  end

  # Validation

  validates_presence_of :username, on: :create
  validates_length_of :username, within: 3..40

  validates_presence_of :password, if: :password_required?
  validates_length_of :password, minimum: 4, if: :password_required?
  validates_confirmation_of :password, if: :password_required?

  validates_uniqueness_of :username
  validates_uniqueness_of :email
end
