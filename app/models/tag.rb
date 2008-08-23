=begin
RailsCollab
-----------
Copyright (C) 2007 - 2008 James S Urquhart (jamesu at gmail.com)This program is free software; you can redistribute it and/ormodify it under the terms of the GNU General Public Licenseas published by the Free Software Foundation; either version 2of the License, or (at your option) any later version.This program is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied warranty ofMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See theGNU General Public License for more details.You should have received a copy of the GNU General Public Licensealong with this program; if not, write to the Free SoftwareFoundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
=end

class Tag < ActiveRecord::Base
	include ActionController::UrlWriter
	
	belongs_to :project
	belongs_to :created_by, :class_name => 'User', :foreign_key => 'created_by_id'
	
	belongs_to :rel_object, :polymorphic => true
	
	acts_as_ferret :fields => [:tag, :project_id, :is_private], :store_class_name => true
	
	before_create :process_params
	 
	def process_params
	end
	
	def objects
		return Tag.find_objects(self.name)
	end
	
	def object_name
		self.tag
	end
	
	def object_url
		url_for :only_path => true, :controller => 'project', :action => 'tags', :id => self.tag, :active_project => self.project_id
	end
	
	def self.priv_scope(include_private)
	  if include_private
	    yield
	  else
	    with_scope :find => { :conditions =>  ['is_private = ?', false] } do 
	      yield 
	    end
	  end
	end
	
	def self.find_objects(tag_name, project, is_public)
		tag_conditions = is_public ?
		                 ['project_id = ? AND tag = ? AND is_private = ?', project.id, tag_name, false] : 
		                 ['project_id = ? AND tag = ?', project.id, tag_name]
		
		Tag.find(:all, :conditions => tag_conditions).collect do |tag|
			tag.rel_object
		end
	end
	
	def self.clear_by_object(object)
		Tag.delete_all(['project_id = ? AND rel_object_type = ? AND rel_object_id = ?', object.project_id, object.class.to_s, object.id])
	end
	
	def self.set_to_object(object, taglist, force_user=0)
		self.clear_by_object(object)
		set_private = object.is_private.nil? ? false : object.is_private
		set_user = force_user == 0 ? (object.updated_by.nil? ? object.created_by : object.updated_by) : force_user
		
		Tag.transaction do
		  	taglist.each do |tag_name|
				Tag.create(:tag => tag_name.strip, :project => object.project, :rel_object => object, :created_by => set_user, :is_private => set_private)
			end
		end
	end
	
	def self.list_by_object(object)
		return Tag.find(:all, :conditions => ['rel_object_type = ? AND rel_object_id = ?', object.class.to_s, object.id]).collect do |tag|
			tag.tag
		end
	end
	
	def self.list_by_project(project, is_public, to_text=true)
		tag_conditions = is_public ?
		                 ['project_id = ? AND is_private = ?', project.id, false] : 
		                 ['project_id = ?', project.id]
		
		tags = Tag.find(:all, :group => 'tag', :conditions => tag_conditions, :order => 'tag', :select => 'tag')
		
		return tags unless to_text
		return tags.collect do |tag|
			tag.tag
		end
	end
	
	def self.count_by(tag_name, project, is_public)
		tag_conditions = is_public ? 
		                 ["project_id = ? AND is_private = ? AND tag = ?", project.id, false, tag_name] :
		                 ["project_id = ? AND tag = ?", project.id, tag_name]
		
		tags = Tag.find(:all, :conditions => tag_conditions, :select => 'id')
		
		return tags.length
	end
end
