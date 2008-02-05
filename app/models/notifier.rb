class Notifier < ActionMailer::Base

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
