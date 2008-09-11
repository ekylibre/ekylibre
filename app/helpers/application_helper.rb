# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def menu_modules
    modules = [:index, :accountancy, :sales, :purchases, :stocks]
    code = ''
    action = action_name.to_sym 
    for m in modules
      if m==action
        code += content_tag 'strong', l(:guide,m,:title)
      else
        code += link_to(l(:guide,m,:title), :controller=>:guide, :action=>m)+' '
      end
    end
    code
  end
end
