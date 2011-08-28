module SessionsHelper
  def page_title
    case action_name
      when 'new', 'create' then I18n.t('login')
      else super
    end
  end
end
