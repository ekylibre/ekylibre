# ##### BEGIN LICENSE BLOCK #####
# Ekylibre - Simple ERP
# Copyright (C) 2009 Brice Texier, Thibaud Merigon
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

  def steps_tag(record, steps, options={})
    name = options[:name] || record.class.name.underscore
    state_method = options[:state_method] || :state
    state = record.send(state_method).to_s
    code = ''
    for step in steps
      title = tc("#{name}_steps.#{step[:name]}")
      classes  = "step"
      classes += " active" if step[:actions].detect{ |url| not url.detect{|k, v| params[k].to_s != v.to_s}} # url = {:action=>url.to_s} unless url.is_a? Hash
      if step[:states].include?(state)
        classes += " usable"
        title = link_to(title, step[:actions][0].merge(:id=>record.id)) 
      end
      code += content_tag(:td, '&nbsp;'.html_safe, :class=>'transition') unless code.blank?
      code += content_tag(:td, title, :class=>classes)
    end
    code = content_tag(:tr, code.html_safe)
    code = content_tag(:table, code.html_safe, :class=>:stepper)
    code.html_safe
  end

  SALES_STEPS = [
                 {:name=>:products,   :actions=>[{:action=>:sale, :step=>:products}, :sale_create, :sale_update, :sale_line_create, :sale_line_update], :states=>['aborted', 'draft', 'estimate', 'refused', 'order', 'invoice']},
                 {:name=>:deliveries, :actions=>[{:action=>:sale, :step=>:deliveries}, :outgoing_delivery_create, :outgoing_delivery_update], :states=>['order', 'invoice']},
                 {:name=>:summary,    :actions=>[{:action=>:sale, :step=>:summary}], :states=>['invoice']}
                ].collect{|s| {:name=>s[:name], :actions=>s[:actions].collect{|u| u={:action=>u.to_s} unless u.is_a?(Hash); u}, :states=>s[:states]}}

  def sales_steps
    steps_tag(@sale, SALES_STEPS, :name=>:sales)
  end

  PURCHASE_STEPS = [
                    {:name=>:products,   :actions=>[{:action=>:purchase, :step=>:products}, :purchase_create, :purchase_update, :purchase_line_create, :purchase_line_update, :purchase_line_delete], :states=>['aborted', 'draft', 'estimate', 'refused', 'order', 'invoice']},
                    {:name=>:deliveries, :actions=>[{:action=>:purchase, :step=>:deliveries}, :incoming_delivery_create, :incoming_delivery_update], :states=>['order', 'invoice']},
                    {:name=>:summary,    :actions=>[{:action=>:purchase, :step=>:summary}], :states=>['invoice']}
                   ].collect{|s| {:name=>s[:name], :actions=>s[:actions].collect{|u| u={:action=>u.to_s} unless u.is_a?(Hash); u}, :states=>s[:states]}}

  def purchase_steps
    steps_tag(@purchase, PURCHASE_STEPS, :name=>:purchase)
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
