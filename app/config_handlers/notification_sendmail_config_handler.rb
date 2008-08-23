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

class NotificationSendmailConfigHandler < ConfigHandler
	
	def value
		res = YAML.load(@rawValue)
		return res.nil? ? {} : {:location => res['location'], 
		                        :arguments => res['arguments']}
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
		"<label for=\"#{name}[location]\">#{:notification_sendmail_location.l}</label>" + text_field_tag("#{name}[location]", values[:location], options.merge(:class => 'middle') )+
		"<label for=\"#{name}[arguments]\">#{:notification_sendmail_arguments.l}</label>" + text_field_tag("#{name}[arguments]", values[:arguments], options.merge(:class => 'middle'))
	end
end
