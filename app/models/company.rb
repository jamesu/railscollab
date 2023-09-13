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

  has_and_belongs_to_many :projects, join_table: :project_companies

  has_one_attached :logo do |attachable|
    attachable.variant :thumb, resize_to_limit: [50, 50]
  end

  before_create :process_params
  before_update :process_update_params
  before_destroy :process_destroy

  def process_params
  end

  def process_update_params
  end

  def process_destroy
  end

  def self.owner(reload = false)
    Company.where(client_of_id: nil).first
  end

  def auto_assign_users
    self.users.where(auto_assign: true)
  end

  def is_owner?
    self.client_of.nil?
  end

  def updated?
    !self.updated_on.nil?
  end

  def is_part_of(project)
    return true if self.is_owner? and (project.created_by.company_id == self.id)
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
    proj_users = Person.where(project_id: project).select("user_id")
    query_users = proj_users.collect { |user| user.user_id }
    User.where(id: query_users, company_id: id)
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

  # Accesibility

  #attr_accessible :name, :time_zone, :email, :homepage, :phone_number, :fax_number, :address, :address2, :city, :state, :zipcode, :country

  # Validation

  validates_uniqueness_of :name
end
