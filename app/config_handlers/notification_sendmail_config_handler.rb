#==
# RailsCollab
# Copyright (C) 2008 James S Urquhart
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

class NotificationSendmailConfigHandler < ConfigHandler
	
	def value
		res = YAML.load(@rawValue)
		return res.nil? ? {} : {:location => res['location'], 
		                        :arguments => res['arguments']}
	end
	
	def value=(val)
		if val.class == String
		  @rawValue = val
		else
		  @rawValue = YAML.dump(val).to_s
		end
	end
	
	def render(name, options)
	    values = self.value
		"<label for=\"#{name}[location]\">#{I18n.t('notification_sendmail_location')}</label>" + text_field_tag("#{name}[location]", values[:location], options.merge(:class => 'middle') )+
		"<label for=\"#{name}[arguments]\">#{I18n.t('notification_sendmail_arguments')}</label>" + text_field_tag("#{name}[arguments]", values[:arguments], options.merge(:class => 'middle'))
	end
end
