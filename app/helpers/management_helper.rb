module ManagementHelper

  def sales_steps
    code = ''
    @step.to_s
    attributes = {}
    for x in 1..7
      attributes[:class] = if x == @step
                             :master
                           elsif x-@step == 1
                             :right
                           elsif x-@step == -1
                             :left
                           else
                             :standard
                           end
      code += content_tag(:td, x, attributes)
    end
    code = content_tag(:tr, code)
    code = content_tag(:table, code, :class=>:stepper)
    code
  end
  
end
