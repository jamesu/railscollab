#==
# RailsCollab
# Copyright (C) 2007 - 2008 James S Urquhart
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

class Notifier < ActionMailer::Base
  default_url_options[:host] = AppConfig.site_url

  def message(user, msg, sent_at = Time.now)
    @subject    = "#{AppConfig.site_name} - New message #{msg.title}"
    @recipients = user.email
    @from       = AppConfig.notification_email_address
    @sent_on    = sent_at
    @headers    = {}
	
	@body       = {
		:site_name => AppConfig.site_name,
		:message => msg,
		:user => user,
		:sent_on => sent_at
	}
  end

  def message_comment(user, comment, msg, sent_at = Time.now)
    @subject    = "#{AppConfig.site_name} - New comment for #{msg.title}"
    @recipients = user.email
    @from       = AppConfig.notification_email_address
    @sent_on    = sent_at
    @headers    = {}
	
	@body       = {
		:site_name => AppConfig.site_name,
		:message => msg,
		:comment => comment,
		:user => user,
		:sent_on => sent_at
	}
  end
  
  def password_reset(user, sent_at = Time.now)
    @subject    = "#{AppConfig.site_name} - Reset password request"
    @recipients = user.email
    @from       = AppConfig.notification_email_address
    @sent_on    = sent_at
    @headers    = {}
	
	@body       = {
		:site_name => AppConfig.site_name,
		:user => user,
		:sent_on => sent_at
	}
  end
  
  def account_new_info(user, password, sent_at = Time.now)
    @subject    = "#{AppConfig.site_name} - Your account has been created"
    @recipients = user.email
    @from       = AppConfig.notification_email_address
    @sent_on    = sent_at
    @headers    = {}
	
	@body       = {
		:site_name => AppConfig.site_name,
		:user => user,
		:password => password,
		:sent_on => sent_at
	}
  end

end
