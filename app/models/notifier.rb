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
end
