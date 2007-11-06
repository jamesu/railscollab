=begin
RailsCollab
-----------
Copyright (C) 2007 James S Urquhart (jamesu at gmail.com)This program is free software; you can redistribute it and/ormodify it under the terms of the GNU General Public Licenseas published by the Free Software Foundation; either version 2of the License, or (at your option) any later version.This program is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied warranty ofMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See theGNU General Public License for more details.You should have received a copy of the GNU General Public Licensealong with this program; if not, write to the Free SoftwareFoundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
=end

class FileRepo < ActiveRecord::Base
	set_table_name 'file_repo'
	
	belongs_to :project_file_revision, :foreign_key => 'repository_id'
	
	# Helpers
	
	def self.handle_storage(value)
		case AppConfig.file_upload_storage
			when 'file_system'
				return nil
			when 'local_database'
			    file_repo = FileRepo.new(:content => value, :order => 0)
				file_repo.save!
				return file_repo.id
		end
		
		return nil
	end
	
	def self.handle_update(id, value)
		case AppConfig.file_upload_storage
			when 'file_system'
				return nil
			when 'local_database'
			    begin
			      file_repo = FileRepo.find(id)
			    rescue ActiveRecord::RecordNotFound
			      return nil
   				end
				file_repo.content = value
				file_repo.save!
				return file_repo.id
		end
		
		return nil
	end
	
	def self.handle_delete(id)
		case AppConfig.file_upload_storage
			when 'file_system'
				return true
			when 'local_database'
			    begin
			      file_repo = FileRepo.find(id)
			    rescue ActiveRecord::RecordNotFound
			      return false
   				end
				file_repo.destroy
				return true
		end
		
		return false
	end
	
	def self.get_data(id)
		case AppConfig.file_upload_storage
			when 'file_system'
				return nil
			when 'local_database'
			    begin
			      file_repo = FileRepo.find(id)
			    rescue ActiveRecord::RecordNotFound
			      return nil
   				end
				return file_repo.content
		end
		
		return nil
	end
end
