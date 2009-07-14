module AccessHelper
  def page_title
    case action_name
      when 'reset_password' then @initial_signup ? :set_password.l : :reset_password.l
      else super
    end
  end
end
