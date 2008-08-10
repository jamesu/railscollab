=begin
RailsCollab
-----------
Copyright (C) 2007 - 2008 James S Urquhart (jamesu at gmail.com)This program is free software; you can redistribute it and/ormodify it under the terms of the GNU General Public Licenseas published by the Free Software Foundation; either version 2of the License, or (at your option) any later version.This program is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied warranty ofMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See theGNU General Public License for more details.You should have received a copy of the GNU General Public Licensealong with this program; if not, write to the Free SoftwareFoundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
=end

class AccountSweeper < ActionController::Caching::Sweeper

  observe User
  
  def after_create(data)
  	expire_account(data)
  end
  
  def after_save(data)
  	expire_account(data)
  end
  
  def after_destroy(data)
  	expire_account(data)
  end
  
  def expire_account(data)
    puts "==Expire account=="
  	expire_page(:controller => 'account', :action => 'avatar', :id => data.id, :format => 'png')
  end
end
