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

class Tag < ApplicationRecord
  include Rails.application.routes.url_helpers

  belongs_to :project
  belongs_to :created_by, class_name: "User", foreign_key: "created_by_id"

  belongs_to :rel_object, polymorphic: true

  before_create :process_params

  def process_params
  end

  def objects
    return Tag.find_objects(self.tag, self.project, !self.is_private)
  end

  def object_name
    self.tag
  end

  def object_url(host = nil)
    project_tags_url(self.project, self.tag, only_path: host.nil?, host: host)
  end

  def self.find_objects(tag_name, project, is_public)
    tag_conditions = is_public ?
      ["project_id = ? AND tag = ? AND is_private = ?", project.id, tag_name, false] :
      ["project_id = ? AND tag = ?", project.id, tag_name]

    Tag.where(tag_conditions).collect { |tag| tag.rel_object }
  end

  def self.clear_by_object(object)
    Tag.where(["project_id = ? AND rel_object_type = ? AND rel_object_id = ?", object.project_id, object.class.to_s, object.id]).delete_all
  end

  def self.set_to_object(object, taglist, force_user = 0)
    self.clear_by_object(object)
    set_private = object.is_private.nil? ? false : object.is_private
    set_user = force_user == 0 ? (object.updated_by.nil? ? object.created_by : object.updated_by) : force_user

    Tag.transaction do
      taglist.each do |tag_name|
        Tag.create(tag: tag_name.strip, project: object.project, rel_object: object, created_by: set_user, is_private: set_private)
      end
    end
  end

  def self.list_by_object(object)
    tags = Tag.where(["rel_object_type = ? AND rel_object_id = ?", object.class.to_s, object.id])

    tags.collect { |tag| tag.tag }
  end

  def self.list_by_project(project, is_public)
    tag_conditions = is_public ?
      ["project_id = ? AND is_private = ?", project.id, false] :
      ["project_id = ?", project.id]

    return Tag.where(tag_conditions).group("tag").order("tag ASC").select("tag")
  end

  def self.count_by(tag_name, project, is_public)
    tag_conditions = is_public ?
      ["project_id = ? AND is_private = ? AND tag = ?", project.id, false, tag_name] :
      ["project_id = ? AND tag = ?", project.id, tag_name]

    tags = Tag.where(tag_conditions).select("id")

    tags.length
  end


  # Search
  register_meilisearch

  meilisearch index_uid: 'Tag', primary_key: :ms_id do
    attribute :tag
    attribute :project

    filterable_attributes [:project]
  end
end
