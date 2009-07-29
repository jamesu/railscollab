module SessionsHelper
  def page_title
    case action_name
      when 'new', 'create' then :login.l
      else super
    end
  end
end
