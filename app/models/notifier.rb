#==
# RailsCollab
# Copyright (C) 2007 - 2011 James S Urquhart
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
  default_url_options[:host] = Rails.configuration.site_url

  def message(user, msg, sent_at = Time.now)
    @subject    = "#{Rails.configuration.site_name} - #{I18n.t('notifier_subject_new_message', :title => msg.title)}"
    @recipients = user.email
    @from       = Rails.configuration.notification_email_address
    @sent_on    = sent_at
    @headers    = {}
	
	@body       = {
		:site_name => Rails.configuration.site_name,
		:message => msg,
		:user => user,
		:sent_on => sent_at
	}
  end

  def task(user, task, sent_at = Time.now)
    @subject    = "#{Rails.configuration.site_name} - #{I18n.t('notifier_subject_new_task')}"
    @recipients = user.email
    @from       = Rails.configuration.notification_email_address
    @sent_on    = sent_at
    @headers    = {}
	
	@body       = {
		:site_name => Rails.configuration.site_name,
		:task => task,
		:user => user,
		:sent_on => sent_at
	}
  end

  def milestone(user, milestone, sent_at = Time.now)
    @subject    = "#{Rails.configuration.site_name} - #{I18n.t('notifier_subject_new_milestone', :name => milestone.name)}"
    @recipients = user.email
    @from       = Rails.configuration.notification_email_address
    @sent_on    = sent_at
    @headers    = {}
	
	@body       = {
		:site_name => Rails.configuration.site_name,
		:milestone => milestone,
		:user => user,
		:sent_on => sent_at
	}
  end

  def message_comment(user, comment, msg, sent_at = Time.now)
    @subject    = "#{Rails.configuration.site_name} - #{I18n.t('notifier_subject_new_comment', :title => msg.title)}"
    @recipients = user.email
    @from       = Rails.configuration.notification_email_address
    @sent_on    = sent_at
    @headers    = {}
	
	@body       = {
		:site_name => Rails.configuration.site_name,
		:message => msg,
		:comment => comment,
		:user => user,
		:sent_on => sent_at
	}
  end
  
  def password_reset(user, sent_at = Time.now)
    @subject    = "#{Rails.configuration.site_name} - #{I18n.t('notifier_subject_reset_password_request')}"
    @recipients = user.email
    @from       = Rails.configuration.notification_email_address
    @sent_on    = sent_at
    @headers    = {}
	
	@body       = {
		:site_name => Rails.configuration.site_name,
		:user => user,
		:sent_on => sent_at
	}
  end
  
  def account_new_info(user, password, sent_at = Time.now)
    @subject    = "#{Rails.configuration.site_name} - #{I18n.t('notifier_subject_new_account')}"
    @recipients = user.email
    @from       = Rails.configuration.notification_email_address
    @sent_on    = sent_at
    @headers    = {}
	
	@body       = {
		:site_name => Rails.configuration.site_name,
		:user => user,
		:password => password,
		:sent_on => sent_at
	}
  end

end
