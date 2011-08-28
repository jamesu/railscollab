module PasswordsHelper
  def page_title
    case action_name
      when 'new', 'create' then I18n.t('forgot_password')
      when 'edit', 'update' then @initial_signup ? I18n.t('set_password') : I18n.t('reset_password')
    end
  end
end
