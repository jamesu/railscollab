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

class Company < ActiveRecord::Base
  include ActionController::UrlWriter

  belongs_to :client_of, :class_name => 'Company', :foreign_key => 'client_of_id'

  belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
  belongs_to :updated_by, :class_name => 'User', :foreign_key => 'updated_by_id'

  has_many :clients, :class_name => 'Company', :foreign_key => 'client_of_id'
  has_many :users
  has_many :auto_assign_users, :class_name => 'User', :foreign_key => 'company_id', :conditions => ['auto_assign = ?', true]

  has_and_belongs_to_many :projects,  :join_table => :project_companies
  
  has_attached_file :logo, :styles => { :thumb => "50x50" }, :default_url => ''

  before_create :process_params
  before_update :process_update_params
  before_destroy :process_destroy

  @@cached_owner = nil

  def process_params
  end

  def process_update_params
  end

  def process_destroy
  end

  def self.owner(reload=false)
    @@cached_owner = nil if reload
    @@cached_owner ||= Company.first(:conditions => 'client_of_id IS NULL')
  end

  def is_owner?
    self.client_of == nil
  end

  def updated?
    !self.updated_on.nil?
  end

  def is_part_of(project)
    return true if self.is_owner? and (project.created_by.company_id == self.id)
    return true if project.company_ids.include?(self.id)
    false
  end

  def self.can_be_created_by(user)
    user.is_admin and user.member_of_owner?
  end

  def can_be_edited_by(user)
    user.is_admin and (user.company == self or user.member_of_owner?)
  end

  def can_be_deleted_by(user)
    user.is_admin and user.member_of_owner?
  end

  def can_be_seen_by(user)
    true
  end

  def client_can_be_added_by(user)
    user.is_admin and user.member_of_owner?
  end

  def can_be_removed_by(user)
    !self.is_owner? and user.is_admin and user.member_of_owner?
  end

  def can_be_managed_by(user)
    user.is_admin? and !self.is_owner?
  end

  def has_logo?
    self.logo?
  end

  def logo_url
    if !logo?
      "/themes/#{AppConfig.site_theme}/images/logo.gif"
    else
      logo.url
    end
  end

  def users_on_project(project)
    proj_users = ProjectUser.all(:conditions => ['project_id = ?', project.id], :select => 'user_id')
    query_users = proj_users.collect{ |user| user.user_id }
    User.all(:conditions => { :id => query_users, :company_id => self.id })
  end

  def object_name
    self.name
  end

  def object_url
    url_for :only_path => true, :controller => 'company', :action => 'card', :id => self.id
  end

  def country_code
    self.country
  end

  def country_code=(value)
    self.country = value
  end

  def country_name
    return TZInfo::Country.get(self.country).name
  end

  def country_name=(value)
    found_country = TZInfo::Country.all.detect{ |country| country.name == value }
    self.country = found_country.code unless found_country.nil?
  end

  def self.select_list
    self.all.collect{ |company| [company.name, company.id] }
  end

  # Accesibility

  attr_accessible :name, :time_zone, :email, :homepage, :phone_number, :fax_number, :address, :address2, :city, :state, :zipcode, :country_code

  # Validation

  validates_uniqueness_of :name
end
