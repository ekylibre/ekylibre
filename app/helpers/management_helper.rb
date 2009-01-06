module ManagementHelper

  def sales_steps
    code = content_tag(:td, '', :class=>:first)
    @step.to_s
    attributes = {:flex=>1}
    for x in 1..7
      attributes[:class] = 'standard '+
        if x == @step
          'master'
        elsif x-@step == 1
          'right'
        elsif x-@step == -1
          'left'
        else
          'other'
        end
      link = link_to(lc(('sales_step_'+x.to_s).to_sym), :action=>:sales)
      code += content_tag(:td, link, attributes)
    end
    code += content_tag(:td, '', :class=>:last)
    code = content_tag(:tr, code)
    code = content_tag(:table, code, :class=>:stepper, :flex=>1)
    code
  end
  
end
