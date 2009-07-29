module PasswordsHelper
  def page_title
    case action_name
      when 'new', 'create' then :forgot_password.l
      when 'edit', 'update' then @initial_signup ? :set_password.l : :reset_password.l
    end
  end
end
