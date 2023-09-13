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

class MailNotifier < ApplicationMailer
  default from: Rails.configuration.railscollab.notification_email_address

  def new_message(user, msg, sent_at = Time.now)
    @site_name = Rails.configuration.railscollab.site_name
    @message = msg
    @user = user
    @sent_on = sent_at

    mail(to: user.email, subject: "#{Rails.configuration.railscollab.site_name} - #{I18n.t("notifier_subject_new_message", @title = msg.title)}")
  end

  def task(user, task, sent_at = Time.now)
    @site_name = Rails.configuration.railscollab.site_name,
                 @task = task,
                 @user = user,
    @sent_on = sent_at

    mail(to: user.email, subject: "#{Rails.configuration.railscollab.site_name} - #{I18n.t("notifier_subject_new_task")}")
  end

  def milestone(user, milestone, sent_at = Time.now)
    @site_name = Rails.configuration.railscollab.site_name,
                 @milestone = milestone,
                 @user = user,
    @sent_on = sent_at

    mail(to: user.email, subject: "#{Rails.configuration.railscollab.site_name} - #{I18n.t("notifier_subject_new_milestone", @name = milestone.name)}")
  end

  def message_comment(user, comment, msg, sent_at = Time.now)
    @site_name = Rails.configuration.railscollab.site_name,
                 @message = msg,
                 @comment = comment,
                 @user = user,
    @sent_on = sent_at

    mail(to: user.email, subject: "#{Rails.configuration.railscollab.site_name} - #{I18n.t("notifier_subject_new_comment", @title = msg.title)}")
  end

  def password_reset(user, sent_at = Time.now)
    @site_name = Rails.configuration.railscollab.site_name,
                 @user = user,
    @sent_on = sent_at

    mail(to: user.email, subject: "#{Rails.configuration.railscollab.site_name} - #{I18n.t("notifier_subject_reset_password_request")}")
  end

  def account_new_info(user, password, sent_at = Time.now)
    @site_name = Rails.configuration.railscollab.site_name,
                 @user = user,
                 @password = password,
    @sent_on = sent_at

    mail(to: user.email, subject: "#{Rails.configuration.railscollab.site_name} - #{I18n.t("notifier_subject_new_account")}")
  end
end
