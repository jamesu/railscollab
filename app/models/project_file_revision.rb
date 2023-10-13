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

class ProjectFileRevision < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :project
  belongs_to :project_file, foreign_key: "file_id"

  belongs_to :created_by, class_name: "User", foreign_key: "created_by_id"
  belongs_to :updated_by, class_name: "User", foreign_key: "updated_by_id", optional: true

  has_one_attached :data do |attachable|
    attachable.variant :thumb, resize_to_limit: [50, 50]
  end

  before_create :process_params
  before_update :process_update_params
  before_destroy :process_destroy

  @@content_types = ["image/jpeg", "image/pjpeg", "image/gif", "image/png", "image/x-png", "image/jpg"]

  def thumbnailable?(file)
    @@content_types.include?(file.content_type)
  end

  def process_params
    self.project ||= project_file.project
  end

  def process_update_params
    Activity.new_log(self, self.updated_by, :edit, self.project_file.is_private, self.project_file.project)
  end

  def process_destroy
    Activity.new_log(self, self.updated_by, :delete, self.project_file.is_private, self.project_file.project)
  end

  def project_id
    self.project_file.project_id
  end

  def upload_file
    nil
  end

  def upload_file=(value)
    self.filesize = value.size
    value.content_type ||= "text/data"
    self.type_string = value.content_type.chomp

    # Figure out the intended file type
    extension = value.original_filename.split(".", 2)[-1]

    # Store
    self.data = value
    self.has_thumbnail = thumbnailable?(value)
  end

  def is_private
    self.project_file.is_private
  end

  def object_name
    self.project_file.filename
  end

  def object_url(host = nil)
    download_project_file_url(self.project,
                              self,
                              only_path: host.nil?,
                              host: host) + "\#revision#{self.id}"
  end

  def icon_url
    "/filetypes/unknown.png"
  end

  # Search
  register_meilisearch
end
