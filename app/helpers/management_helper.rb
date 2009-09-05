module ManagementHelper
  STEPS = ['sale_orders_create', 'sales_products', 'sales_deliveries', 'sales_payments']
  #STEPS = ['sales_general', 'sales_products', 'sales_deliveries', 'sales_invoices']


  def sales_steps
    code = content_tag(:td, '', :class=>'side first')
    @step = STEPS.index(action_name)+1
    tds = STEPS.size*2
    attributes = {:flex=>1}
    for x in 0..tds
      @active_link = link_to(tc(('sales_step_'+((x+1)/2).to_s).to_sym), :action=>STEPS[x == 0 ? x : x/2], :id=>@sale_order.id.to_s)
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
        
        if @sale_order.estimate?
          link = @passive_link
        elsif @sale_order.active?
          link = @active_link 
        else
          link = @passive_link
        end
        link = @active_link
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








  SALE_STEPS = [{:name=>:general,    :actions=>[:sale_order_update, :sale_order_create], :states=>[:active, :complete, :estimate]},
                {:name=>:products,   :actions=>[:sale_orders_lines, :sale_order_line_create, :sale_order_line_update], :states=>[:estimate, :active, :complete]},
                {:name=>:deliveries, :actions=>[:sale_orders_deliveries, :sale_order_deliveries_create, :sale_order_deliveries_update], :states=>[:active, :complete]},
                {:name=>:summary,    :actions=>[:sale_order], :states=>[:active, :complete]}]
  SALE_ORDER_SATES = {'A'=>:active, 'C'=>:complete, 'E'=>:estimate}

  def sale_steps
    code = ''
    last_active = false
    SALE_STEPS.each_index do |index|
      title = tc('sale_steps.'+SALE_STEPS[index][:name].to_s)
      active = (SALE_STEPS[index][:actions].include?(action_name.to_sym) ? ' active' : nil)
      if not @sale_order.new_record? and active.nil? and SALE_STEPS[index][:states].include?(SALE_ORDER_SATES[@sale_order.state])
        title = link_to(title, :action=>SALE_STEPS[index][:actions][0], :id=>@sale_order.id.to_s)
      end
      code += content_tag(:td, '&nbsp;', :class=>'transit'+(active ? ' left' : (last_active ? ' right' : nil)).to_s) if index>0
      code += content_tag(:td, title, :class=>'step'+active.to_s)
      last_active = active
    end
    code = content_tag(:tr, code)
    code = content_tag(:table, code, :class=>:stepper)
    code
  end




  
end
