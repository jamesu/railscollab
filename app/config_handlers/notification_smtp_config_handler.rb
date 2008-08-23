=begin
RailsCollab
-----------

Copyright (C) 2008 James S Urquhart (jamesu at gmail.com)

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

class NotificationSMTPConfigHandler < ConfigHandler
	
	def value
		res = YAML.load(@rawValue)
		return res.nil? ? {} : {:address => res['address'], 
		                        :port => res['port'],
		                        :user_name => res['user_name'],
		                        :password => res['password'],
		                        :authentication => res['authentication']}
	end
	
	def value=(val)
		if val.class == String:
		  @rawValue = val
		else
		  @rawValue = YAML.dump(val).to_s
		end
	end
	
	def render(name, options)
		values = self.value
		      
		"<label for=\"#{name}[address]\">#{:notification_smtp_address.l}</label>" + text_field_tag("#{name}[address]", values[:address], options.merge(:class => 'middle') ) +
		"<label for=\"#{name}[port]\">#{:notification_smtp_port.l}</label>" + text_field_tag("#{name}[port]", values[:port], options.merge(:class => 'middle')) +
		"<label for=\"#{name}[user_name]\">#{:notification_smtp_username.l}</label>" + text_field_tag("#{name}[user_name]", values[:user_name], options.merge(:class => 'middle')) +
		"<label for=\"#{name}[password]\">#{:notification_smtp_password.l}</label>" + text_field_tag("#{name}[password]", values[:password], options.merge(:class => 'middle')) +
		"<label for=\"#{name}[authentication]\">#{:notification_smtp_authentication.l}</label>" + text_field_tag("#{name}[authentication]", values[:authentication], options.merge(:class => 'middle'))
	end
end
