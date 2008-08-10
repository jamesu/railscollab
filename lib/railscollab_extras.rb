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

class String
	def twist(twister)
	  return self if self.length != twister.length
	  
	  untwist_arr = self.split('')
	  twist_arr = twister.clone()
	  twister.length.times do |ti|
	  	twist_arr[twister[ti]] = untwist_arr[ti]
	  end
	  
      return twist_arr.join()
	end
	
	def untwist(twister)
	  return self if self.length != twister.length
      
      twist_arr = self.split('')
      untwist_arr = twister.clone()
      twister.length.times do |ti|
      	untwist_arr[ti] = twist_arr[twister[ti]]
      end
      
      return untwist_arr.join()
	end
	
	def valid_hash?
		(self =~ /^([a-f0-9]*)$/) != nil
	end
	
	def sanitize_filename
		fname = File.basename(self)
		fname.gsub(/[^\w\.\-]/,'_') 
	end
	
	def excerpt(chars=100, more='...')
		return self.length > chars ? "#{self[0...chars]}#{more}" : self
	end
end

#class RedCloth
#  def filter_html; true; end
#end