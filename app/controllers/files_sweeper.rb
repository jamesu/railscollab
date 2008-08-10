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

class FilesSweeper < ActionController::Caching::Sweeper

  observe ProjectFileRevision
  
  def after_create(data)
  	expire_thumbnail(data)
  end
  
  def after_save(data)
  	expire_thumbnail(data)
  end
  
  def after_destroy(data)
  	expire_thumbnail(data)
  end
  
  def expire_thumbnail(data)
	# This should clear out any existing thumbnail
  	expire_page(:controller => 'files', :action => 'thumbnail', :id => data.id, :format => 'jpg')
  end
end
