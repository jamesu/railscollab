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

class Company < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :client_of, class_name: "Company", foreign_key: "client_of_id", optional: true

  belongs_to :created_by, class_name: "User", foreign_key: "created_by_id", optional: true
  belongs_to :updated_by, class_name: "User", foreign_key: "updated_by_id", optional: true

  has_many :clients, class_name: "Company", foreign_key: "client_of_id"
  has_many :users
  has_many :owner_projects, class_name: "Project", foreign_key: "owner_company_id"

  has_and_belongs_to_many :projects, join_table: :project_companies

  has_one_attached :logo do |attachable|
    attachable.variant :thumb, resize_to_limit: [50, 50]
  end

  before_create :process_params
  before_update :process_update_params
  before_destroy :process_destroy

  after_create :update_perms
  after_update :update_perms

  def process_params
  end

  def process_update_params
  end

  def process_destroy
  end

  def people
    Person.joins(:user).where('users.company_id': self.id)
  end

  def self.instance_owner
    Company.where(client_of_id: nil).first
  end

  def auto_assign_users
    self.users.where(auto_assign: true)
  end

  def is_instance_owner?
    self.client_of.nil?
  end

  def updated?
    !self.updated_on.nil?
  end

  def is_part_of(project)
    return true if self.is_instance_owner? and (project.created_by.company_id == self.id)
    return true if project.company_ids.include?(self.id)
    false
  end

  def has_logo?
    self.logo.attached?
  end

  def logo_url
    if !logo.attached?
      "/assets/logo.gif"
    else
      logo.variant(:thumb).url
    end
  end

  def users_on_project(project)
    proj_users = Person.where(project_id: project).select(:user_id).map(&:user_id)
    User.where(id: proj_users, company_id: id)
  end

  # Returns the owner company id
  def perm_company_id
    if !client_of.nil?
      client_of_id
    else
      id
    end
  end

  # Returns incomplete projects belonging to the owner company id
  def perm_project_ids
    if !client_of.nil?
      client_of.owner_projects.where(completed_on: nil).all.map(&:id)
    else
      owner_projects.where(completed_on: nil).all.map(&:id)
    end
  end

  # Returns incomplete projects belonging to the owner company id
  def perm_user_ids
    if !client_of.nil?
      client_of.user_ids + user_ids
    else
      user_ids
    end
  end

  def perms
    return @new_perms_list if !@new_perms_list.nil?
    people.all.map { |ps| ps.get_permissions.map{ |a| "#{ps.project_id}_#{ps.user_id}_#{a}" } }.flatten
  end

  def perms=(value)
    @new_perms_list = value
  end

  def update_perms
    return if @new_perms_list.nil?

    pids = perm_project_ids
    uids = perm_user_ids

    set_perm_list(@new_perms_list, pids, uids)
    @new_perms_list = nil
  end

  def object_name
    self.name
  end

  def object_url(host = nil)
    company_url(self, only_path: host.nil?, host: host)
  end

  def self.select_list
    self.all.collect { |company| [company.name, company.id] }
  end

  # Validation

  validates_uniqueness_of :name

  # Search
  register_meilisearch
end
