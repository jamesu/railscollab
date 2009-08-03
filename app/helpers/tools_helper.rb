module ToolsHelper
  def page_title
    case action_name
      when 'index' then :tools.l
      else super
    end
  end

  def current_tab
    :tools
  end
end
