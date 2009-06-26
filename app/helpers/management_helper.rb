module ManagementHelper
  STEPS = ['sales_general', 'sales_products', 'sales_deliveries', 'sales_invoices', 'sales_payments']
  #STEPS = ['sales_general', 'sales_products', 'sales_deliveries', 'sales_invoices']


  def sales_steps
    code = content_tag(:td, '', :class=>'side first')
    @step = STEPS.index(action_name)+1
    tds = STEPS.size*2
    attributes = {:flex=>1}
    for x in 0..tds
      @active_link = link_to(tc(('sales_step_'+((x+1)/2).to_s).to_sym), :action=>STEPS[x == 0 ? x : x/2].to_s, :id=>@sale_order.id.to_s) 
      @passive_link = tc('sales_step_'+((x+1)/2).to_s) 
      #raise Exception.new @sale_order.inspect
      if x % 2 == 0 # transit
        if @step == x/2+1
          code += content_tag(:td, '&nbsp;', :class=>'transit left')
        elsif @step == x/2
          code += content_tag(:td, '&nbsp;', :class=>'transit right')
        else
          code += content_tag(:td, '&nbsp;', :class=>'transit')
        end
      else # step
        
        if @sale_order.state == "P" or  @sale_order.state == "O"
          link = @passive_link
        elsif @sale_order.state == "L"
          link = x <= 5 ? @active_link : @passive_link
        elsif @sale_order.state == "I" 
          link = x <= 7 ? @active_link : @passive_link
        elsif @sale_order.state == "R" or @sale_order.state ==  "F"
          link = @active_link
        end
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
