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

class Comment < ApplicationRecord
	belongs_to :created_by, class_name: 'User', foreign_key:  'created_by_id'
	belongs_to :updated_by, class_name: 'User', foreign_key:  'updated_by_id', optional: true
	
	belongs_to :rel_object, polymorphic:  true, counter_cache:  true
	
	has_many :attached_file, as:  'rel_object'
	has_many :project_file, through:  :attached_file

	before_validation :process_params, on: :create
	after_create :process_create
	before_update :process_update_params
	before_destroy :process_destroy
	
	scope :is_public, -> { where(is_private: false) }
	 
	def process_params
	  self.project_id ||= self.rel_object.try(:project_id)
	  self.is_anonymous = self.created_by.is_anonymous?
	  
	  true
	end
	
	def process_create
	  Activity.new_log(self, self.created_by, :add, self.is_private, self.rel_object.project)
	end
	
	def process_update_params
	  Activity.new_log(self, self.updated_by, :edit, self.is_private, self.rel_object.project)
	end
	
	def process_destroy
	  AttachedFile.clear_attachments(self)
	  Activity.new_log(self, self.updated_by, :delete, true,  self.rel_object.project)
	end
	
	def last_edited_by_owner?
	 return (self.created_by.member_of_owner? or (!self.updated_by.nil? and self.updated_by.member_of_owner?))
	end
    
  # Helpers

	def object_name
		self.text.excerpt(50)
	end
	
	def object_url(host = nil)
		if self.rel_object
			self.rel_object.object_url(host) + "#objectComments"
		else
			""
		end
	end
	
  def attached_files(with_private)
    if with_private
      project_file
    else
      project_file.where(is_private: false)
    end
  end

  def project
  	rel_object.nil? ? nil : rel_object.project
  end
	
	# Accesibility
	
	#attr_accessible :text, :is_private, :author_name, :author_email
	
	# Validation
	
	validates_presence_of :author_name, if: Proc.new { |obj| obj.is_anonymous }
	validates_presence_of :author_email, if: Proc.new { |obj| obj.is_anonymous }
	
	validates_presence_of :text
	validates_each :is_private, if: Proc.new { |obj| !obj.last_edited_by_owner? } do |record, attr, value|
		record.errors.add attr, I18n.t('not_allowed') if value == true
	end
  
  # Indexing
  define_index do
    indexes :text
    
    has :project_id
    has :is_private
    has :created_on
    has :updated_on
  end
end
