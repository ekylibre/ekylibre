# ##### BEGIN LICENSE BLOCK #####
# Ekylibre - Simple ERP
# Copyright (C) 2009 Brice Texier, Thibaud Mérigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# ##### END LICENSE BLOCK #####

module ManagementHelper

  SALE_STEPS = [
                {:name=>:estimate,   :actions=>[:sales_order_lines, :sales_order_create, :sales_order_update, :sales_order_line_create, :sales_order_line_update], :states=>[:estimate, :active, :complete]},
                {:name=>:deliveries, :actions=>[:sales_order_deliveries, :outgoing_delivery_create, :outgoing_delivery_update], :states=>[:active, :complete]},
                {:name=>:summary,    :actions=>[:sales_order_summary], :states=>[:estimate, :active, :complete]}
               ]
  SALE_ORDER_SATES = {'A'=>:active, 'C'=>:complete, 'E'=>:estimate}

  def sale_steps
    code = ''
    last_active = false
    SALE_STEPS.each_index do |index|
      title = tc('sale_steps.'+SALE_STEPS[index][:name].to_s)
      active = (SALE_STEPS[index][:actions].include?(action_name.to_sym) ? ' active' : nil)
      if not @sales_order.new_record? and active.nil? and SALE_STEPS[index][:states].include?(SALE_ORDER_SATES[@sales_order.state])
        title = link_to(title, :action=>SALE_STEPS[index][:actions][0], :id=>@sales_order.id.to_s)
      end
      # code += content_tag(:td, '&nbsp;'.html_safe, :class=>'transit'+(active ? ' left' : (last_active ? ' right' : nil)).to_s) if index>0
      code += content_tag(:td, '&nbsp;'.html_safe, :class=>'transition') if index>0
      code += content_tag(:td, title, :class=>'step'+active.to_s)
      last_active = active
    end
    code = content_tag(:tr, code.html_safe)
    code = content_tag(:table, code.html_safe, :class=>:stepper)
    code.html_safe
  end
  
  PURCHASE_STEPS = [
                    {:name=>:active, :actions=>[:purchase_order_lines, :purchase_order_create, :purchase_order_update, :purchase_order_line_create, :purchase_order_line_update, :purchase_order_line_delete], :states=>[:active, :complete]},
                    {:name=>:deliveries, :actions=>[:purchase_order_deliveries, :incoming_delivery_create, :incoming_delivery_update], :states=>[:active, :complete]},
                    {:name=>:summary, :actions=>[:purchase_order_summary], :states=>[:active, :complete]}
                   ]

  PURCHASE_ORDER_SATES = {'A'=>:active, 'C'=>:complete}
  
  def purchase_steps
    code = ''
    last_active = false
    PURCHASE_STEPS.each_index do |index|
      title = tc('purchase_steps.'+PURCHASE_STEPS[index][:name].to_s)
      active = (PURCHASE_STEPS[index][:actions].include?(action_name.to_sym) ? ' active' : nil)
      if not @purchase_order.new_record? and active.nil?
        title = link_to(title, :action=>PURCHASE_STEPS[index][:actions][0], :id=>@purchase_order.id.to_s)
      end
      # code += content_tag(:td, '&nbsp;', :class=>'transit'+(active ? ' left' : (last_active ? ' right' : nil)).to_s) if index>0
      code += content_tag(:td, '&nbsp;'.html_safe, :class=>'transition') if index>0
      code += content_tag(:td, title, :class=>'step'+active.to_s)
      last_active = active
    end
    code = content_tag(:tr, code.html_safe)
    code = content_tag(:table, code.html_safe, :class=>:stepper)
    code.html_safe
  end


  def product_stocks_options(product)
    options = []
    options += product.stocks.collect{|x| [x.label, x.id]}
    options += @current_company.warehouses.find(:all, :conditions=>["(product_id=? AND reservoir=?) OR reservoir=?", product.id, true, false]).collect{|x| [x.name, -x.id]}
    return options
  end

  def toggle_tag(name=:orientation, modes = [:vertical, :horizontal])
    raise ArgumentError.new("Invalid name") unless name.to_s.match(/^[a-z\_]+$/)
    pref = @current_user.preference("interface.toggle.#{name}", modes[0].to_s)
    code = ""
    for mode in modes
      # code += link_to("", params.merge(name=>mode), :title=>tl("#{name}.#{mode}"), :class=>"icon im-#{mode}#{' current' if mode.to_s==pref.value}")
      if mode.to_s==pref.value
        code += content_tag(:a, nil, :title=>tl("#{name}.#{mode}"), :class=>"icon im-#{mode} current")
      else
        code += link_to("", params.merge(name=>mode), :title=>tl("#{name}.#{mode}"), :class=>"icon im-#{mode}")
      end
    end
    content_tag(:div, code.html_safe, :class=>"toggle tg-#{name}")
  end


end
