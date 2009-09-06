module ManagementHelper

  SALE_STEPS = [
                {:name=>:estimate,   :actions=>[:sale_order_lines, :sale_order_create, :sale_order_update, :sale_order_line_create, :sale_order_line_update], :states=>[:estimate, :active, :complete]},
                {:name=>:deliveries, :actions=>[:sale_order_deliveries, :sale_order_delivery_create, :sale_order_delivery_update], :states=>[:active, :complete]},
                {:name=>:summary,    :actions=>[:sale_order_summary], :states=>[:estimate, :active, :complete]}
               ]
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
