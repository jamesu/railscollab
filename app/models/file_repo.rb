=begin
RailsCollab
-----------
Copyright (C) 2007 - 2008 James S Urquhart (jamesu at gmail.com)This program is free software; you can redistribute it and/ormodify it under the terms of the GNU General Public Licenseas published by the Free Software Foundation; either version 2of the License, or (at your option) any later version.This program is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied warranty ofMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See theGNU General Public License for more details.You should have received a copy of the GNU General Public Licensealong with this program; if not, write to the Free SoftwareFoundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
=end

require 'aws/s3' unless AppConfig.no_s3
require 'digest/md5'
require 'digest/sha1'

class FileRepo < ActiveRecord::Base
	set_table_name 'file_repo'
	include AWS::S3 unless AppConfig.no_s3
	
	belongs_to :project_file_revision, :foreign_key => 'repository_id'
  
	@@storage_lookup = {:database => 0, :s3 => 1}
	@@storage_id_lookup = @@storage_lookup.invert
  
	def storage
  	  @@storage_id_lookup[self.storage_id]
	end
    
	def storage=(val)
  	  self.storage_id = @@storage_lookup[val.to_sym]
	end
	
	# Helpers
	
	def self.handle_storage(value, id, content_type, is_private=false)
		case AppConfig.file_upload_storage
			when 'amazon_s3'
				return nil if FileRepo.no_s3?
				FileRepo.grab_ensure_s3_bucket
				
				# Grab a few random things...
				tnow = Time.now()
				sec = tnow.tv_usec
				usec = tnow.tv_usec % 0x100000
				rval = rand()
				
				if FileRepo.s3_exists? id
				  rand_hex = Digest::SHA1.hexdigest(sprintf("%s%08x%05x%.8f", 
				                                    rand(32767), 
				                                    sec, usec, rval) + 
				                                    Digest::MD5.hexdigest(value))
				  real_id = "#{rand_hex}-#{id}"
				else
				  real_id = id
				end
				
				# Store via S3Object
				begin
				    S3Object.store(real_id, 
				                   value,
				                   @@s3_bucket, 
				                   :content_type => content_type, 
				                   :access => (is_private ? :private : :public_read ))
				rescue
				    return nil
				end
				
				# Store to FileRepo
				file_repo = FileRepo.create(:content => real_id, :order => 0, :storage => :s3)
				return file_repo.id
				
			when 'local_database'
				file_repo = FileRepo.create(:content => value, :order => 0, :storage => :database)
				return file_repo.id
		end
		
		return nil
	end
	
	def self.handle_update(id, value, content_type, is_private=false)
		begin
		  file_repo = FileRepo.find(id)
		rescue ActiveRecord::RecordNotFound
		  return nil
		end
   		
		case file_repo.storage
			when :s3
				return nil if FileRepo.no_s3?
				FileRepo.grab_ensure_s3_bucket
				
				if FileRepo.s3_exists? file_repo.content
				    begin
				      S3Object.store(file_repo.content, 
				                     value, 
				                     @@s3_bucket, 
				                     :content_type => content_type, 
				                     :access => (is_private ? :private : :public_read ))
				    rescue
				      return nil
				    end
				    
				    return file_repo.id
				else
				    return FileRepo.handle_storage(value, file_repo.content, content_type, is_private)
				end
			when :database
				file_repo.content = value
				file_repo.save!
				return file_repo.id
		end
		
		return nil
	end
	
	def self.handle_delete(id)
		begin
		  file_repo = FileRepo.find(id)
		rescue ActiveRecord::RecordNotFound
		  return false
		end
		
		case file_repo.storage
			when :s3
				return false if FileRepo.no_s3?
				FileRepo.grab_ensure_s3_bucket
				
				begin
				  S3Object.delete(file_repo.content, @@s3_bucket)
				rescue
				  return false
				end
				
				file_repo.destroy
				return true
			when :database
				file_repo.destroy
				return true
		end
		
		return false
	end
	
	def self.get_data(id, allow_url=true, is_private=false)
		begin
		  file_repo = FileRepo.find(id)
		rescue ActiveRecord::RecordNotFound
		  return nil
		end
		
		case file_repo.storage
			when :s3
				return nil if FileRepo.no_s3?
				FileRepo.grab_ensure_s3_bucket
				 
				begin
				  if allow_url
				    return {:url => S3Object.url_for(file_repo.content,
				                                     @@s3_bucket,
				                                     :authenticated => is_private)}
				  else
				    return S3Object.find(file_repo.content, @@s3_bucket).value
				  end
				rescue
				  return nil
				end
			when :database
				return file_repo.content
		end
		
		return nil
	end
	
	def self.no_s3?
	  (AppConfig.no_s3 || AppConfig.storage_s3_login.nil?)
	end
	
	def self.s3_exists?(id)
	   begin
	     foo = S3Object.find(id, @@s3_bucket)
	     return !foo.nil?
	   rescue 
	     return false
	   end
	end
	
	def self.grab_ensure_s3_bucket
	   # Not taking any chances here...
	   the_bucket = nil
	   @@s3_bucket ||= nil
	   if @@s3_bucket.nil?
	       bucket = AppConfig.storage_s3_bucket
	       
	       begin
	           the_bucket = Bucket.find(bucket)
	           @@s3_bucket = bucket
	       rescue
	           begin
	               the_bucket ||= Bucket.create(bucket)
	               @@s3_bucket = bucket
	            rescue
	                   return the_bucket.nil?
	            end
	       end
	   end
	end
end
