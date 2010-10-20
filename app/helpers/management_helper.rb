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

  def steps_tag(record, steps, options={})
    name = options[:name] || record.class.name.underscore
    state_method = options[:state_method] || :state
    code = ''
    for step in steps
      title = tc("#{name}_steps.#{step[:name]}")
      active = step[:actions].detect do |url|
        # url = {:action=>url.to_s} unless url.is_a? Hash
        not url.detect{|k, v| params[k].to_s != v.to_s}
      end
      if not active and step[:states].include?(record.send(state_method))
        title = link_to(title, step[:actions][0].merge(:id=>record.id))
      end
      code += content_tag(:td, '&nbsp;'.html_safe, :class=>'transition') unless code.blank?
      code += content_tag(:td, title, :class=>"step#{' active' if active}")
    end
    code = content_tag(:tr, code.html_safe)
    code = content_tag(:table, code.html_safe, :class=>:stepper)
    code.html_safe
  end

  SALES_STEPS = [
                 {:name=>:products,   :actions=>[{:action=>:sales_order, :step=>:products}, :sales_order_create, :sales_order_update, :sales_order_line_create, :sales_order_line_update], :states=>['aborted', 'draft', 'ready', 'refused', 'processing', 'invoiced', 'finished']},
                 {:name=>:deliveries, :actions=>[{:action=>:sales_order, :step=>:deliveries}, :outgoing_delivery_create, :outgoing_delivery_update], :states=>['processing', 'invoiced', 'finished']},
                 {:name=>:summary,    :actions=>[{:action=>:sales_order, :step=>:summary}], :states=>['invoiced', 'finished']}
                ].collect{|s| {:name=>s[:name], :actions=>s[:actions].collect{|u| u={:action=>u.to_s} unless u.is_a?(Hash); u}, :states=>s[:states]}}

  def sales_steps
    steps_tag(@sales_order, SALES_STEPS, :name=>:sales)
  end

  PURCHASE_STEPS = [
                    {:name=>:products,   :actions=>[{:action=>:purchase_order, :step=>:products}, :purchase_order_create, :purchase_order_update, :purchase_order_line_create, :purchase_order_line_update, :purchase_order_line_delete], :states=>['aborted', 'draft', 'ready', 'refused', 'processing', 'invoiced', 'finished']},
                    {:name=>:deliveries, :actions=>[{:action=>:purchase_order, :step=>:deliveries}, :incoming_delivery_create, :incoming_delivery_update], :states=>['processing', 'invoiced', 'finished']},
                    {:name=>:summary,    :actions=>[{:action=>:purchase_order, :step=>:summary}], :states=>['invoiced', 'finished']}
                   ].collect{|s| {:name=>s[:name], :actions=>s[:actions].collect{|u| u={:action=>u.to_s} unless u.is_a?(Hash); u}, :states=>s[:states]}}

  def purchase_steps
    steps_tag(@purchase_order, PURCHASE_STEPS, :name=>:purchase)
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
