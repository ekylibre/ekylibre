module ManagementHelper
  STEPS = ['sales_general', 'sales_products', 'sales_deliveries', 'sales_invoices', 'sales_payments']


  def sales_steps
    code = content_tag(:td, '', :class=>'side first')
    @step = STEPS.index(action_name)+1
    tds = STEPS.size*2
    attributes = {:flex=>1}
    for x in 0..tds
      if x % 2 == 0 # transit
        if @step == x/2+1
          code += content_tag(:td, '&nbsp;', :class=>'transit left')
        elsif @step == x/2
          code += content_tag(:td, '&nbsp;', :class=>'transit right')
        else
          code += content_tag(:td, '&nbsp;', :class=>'transit')
        end
      else # step
#        link = link_to(tc(('sales_step_'+((x+1)/2).to_s).to_sym), :action=>:sales)
        link = tc('sales_step_'+((x+1)/2).to_s)
        code += content_tag(:td, link, :class=>((x+1)/2 == @step ? 'step active' : 'step' ))
      end
    end

#       attributes[:class] = 'standard '+
#         if x == @step
#           'master'
#         elsif x-@step == 1
#           'right'
#         elsif x-@step == -1
#           'left'
#         else
#           'other'
#         end
#       link = link_to(tc(('sales_step_'+x.to_s).to_sym), :action=>:sales)
#       code += content_tag(:td, link, attributes)
#     end
    code += content_tag(:td, '', :class=>'side last')
    code = content_tag(:tr, code)
    code = content_tag(:table, code, :class=>:stepper)
    code
  end
  
end
