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
                {:name=>:estimate,   :actions=>[:sale_order_lines, :sale_order_create, :sale_order_update, :sale_order_line_create, :sale_order_line_update], :states=>[:estimate, :active, :complete]},
                {:name=>:deliveries, :actions=>[:sale_order_deliveries, :delivery_create, :delivery_update], :states=>[:active, :complete]},
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
  
  PURCHASE_STEPS = [
                    {:name=>:active, :actions=>[:purchase_order_lines, :purchase_order_create, :purchase_order_update, :purchase_order_line_create, :purchase_order_line_update, :purchase_order_line_delete], :states=>[:active, :complete]},
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
      code += content_tag(:td, '&nbsp;', :class=>'transit'+(active ? ' left' : (last_active ? ' right' : nil)).to_s) if index>0
      code += content_tag(:td, title, :class=>'step'+active.to_s)
      last_active = active
    end
    code = content_tag(:tr, code)
    code = content_tag(:table, code, :class=>:stepper)
    code
  end

end
