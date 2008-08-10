=begin
RailsCollab
-----------
Copyright (C) 2007 - 2008 James S Urquhart (jamesu at gmail.com)This program is free software; you can redistribute it and/ormodify it under the terms of the GNU General Public Licenseas published by the Free Software Foundation; either version 2of the License, or (at your option) any later version.This program is distributed in the hope that it will be useful,but WITHOUT ANY WARRANTY; without even the implied warranty ofMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See theGNU General Public License for more details.You should have received a copy of the GNU General Public Licensealong with this program; if not, write to the Free SoftwareFoundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
=end

class ConfigCategory < ActiveRecord::Base
	#has_many :config_options
	
	def display_name
		("category_#{self.name}_name").to_sym.l
	end
	
	def display_description
		("category_#{self.name}_description").to_sym.l
	end
	
	def options
		@config_options ||= ConfigOption.find(:all, :conditions => ['category_name = ?', self.name], :order => 'config_options.option_order ASC')
	end
end
