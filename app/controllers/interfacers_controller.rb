# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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

class InterfacersController < ApplicationController

  # Saves the state of the side bar
  def toggle_side
    # Explicit conversion
    session[:side] = (params[:splitted] == "1" ? false : true)
    render :text=>''    
  end
  
  # Saves the state of the side bar
  def toggle_module
    # Explicit conversion
    shown = (params[:shown].to_i>0 ? true : false)
    session[:modules] ||= {}
    session[:modules][params[:module]] = shown
    @current_user.preference("interface.show_modules.#{params[:module]}", true, :boolean).set(shown)
    render :text=>''
  end
  
  # Saves the last selected tab in a tabbox
  def toggle_tab
    session[:tabbox] ||= {}
    session[:tabbox][params['id']] = params['index']
    render :text=>nil
  end

  # Saves the view mode
  def toggle_view_mode
    session[:view_mode] = params[:mode]
    render :text=>''
  end
  


  # Returns the new list for a "dynamic select" using company's reflections
  def unroll_options
    @options = {}
    for x in [:reflection, :order, :label, :include_blank]
      @options[x] = params[x]
    end
    render :inline=>'<%=options_for_select(@current_company.reflection_options(@options), params[:selected].to_i)-%>'
  end

  def product_trackings
    return unless @product = find_and_check(:product, params[:product_id])
    render :inline=>"<%=options_for_select([['---', '']]+@product.trackings.collect{|x| [x.name, x.id]})-%>", :layout=>false
  end

  def product_units
    return unless @product = find_and_check(:product, params[:product_id])
    render :inline=>"<%=options_for_select(@product.units.collect{|x| [x.name, x.id]})-%>", :layout=>false
  end

  search_for(:account, :columns=>["number:X%", :name], :conditions =>{:company_id=>['@current_company.id']})
  search_for(:all_contacts, :contacts, :columns=>[:address], :conditions =>["company_id = ? AND deleted_at IS NULL", ['@current_company.id']])
  search_for(:attorneys_accounts, :accounts, :columns=>[:number, :name], :conditions=>["company_id=? AND number LIKE ?", ["@current_company.id"], ["@current_company.preferred_third_attorneys_accounts.to_s+'%'"]])

  def self.available_prices_conditions
    code = ""
    code << "c=['#{Price.table_name}.company_id=? AND #{Price.table_name}.active=? AND #{Product.table_name}.active=?', @current_company.id, true, true]\n"
    code << "if session[:current_currency]\n"
    code << "  c[0] << ' AND currency=?'\n"
    code << "  c << session[:current_currency]\n"
    code << "end\n"
    return code
  end


  search_for(:available_prices, :prices, :columns=>["product.code", "product.name", {:name=>:pretax_amount, :code=>"I18n.localize(DATUM, :currency=>RECORD.currency)"}, {:name=>:amount, :code=>"I18n.localize(DATUM, :currency=>RECORD.currency)"}], :joins=>[:product], :conditions=>available_prices_conditions, :order=>"products.name, prices.amount")
  # search_for(:available_prices, :prices, :columns=>["product.code", "product.name", :pretax_amount, :amount], :joins=>[:product], :conditions=>["#{Price.table_name}.company_id=? AND #{Price.table_name}.active=? AND #{Product.table_name}.active=?", ['@current_company.id'], true, true], :order=>"products.name, prices.amount")
  search_for(:clients_accounts, :accounts, :columns=>[:number, :name], :conditions=>["company_id=? AND number LIKE ?", ["@current_company.id"], ["@current_company.preferred_third_clients_accounts.to_s+'%'"]])
  search_for(:client_contacts, :contacts, :columns=>[:address], :conditions=>["company_id = ? AND entity_id = ? AND deleted_at IS NULL", ['@current_company.id'], ['session[:current_entity_id]']])
  search_for(:clients, :entities, :columns=>[:code, :full_name], :conditions => {:company_id=>['@current_company.id'], :client=>true})
  search_for(:collected_account, :account, :columns=>["number:X%", :name], :conditions => {:company_id=>['@current_company.id']})
  search_for(:districts, :columns=>[:name, :code], :conditions=>{:company_id=>['@current_company.id']})
  search_for(:entities, :columns=>[:code, :full_name], :conditions => {:company_id=>['@current_company.id']})
  search_for(:incoming_delivery_contacts, :contact, :columns=>['entity.full_name', :address], :conditions =>["#{Contact.table_name}.company_id = ? AND #{Contact.table_name}.deleted_at IS NULL AND #{Contact.table_name}.entity_id = #{Company.table_name}.entity_id", ['@current_company.id']], :joins=>[:company])
  search_for(:operation_products, :product, :columns=>[:code, :name], :conditions =>{:company_id=>['@current_company.id'], :active=>true})
  search_for(:outgoing_deliveries, :columns=>[:planned_on, "contact.address"], :conditions=>["#{OutgoingDelivery.table_name}.company_id = ? AND transport_id IS NULL", ['@current_company.id']], :joins=>[:contact])
  search_for(:outgoing_delivery_contacts, :contacts, :columns=>['entity.full_name', :address], :conditions=>["#{Contact.table_name}.company_id = ? AND #{Contact.table_name}.deleted_at IS NULL", ['@current_company.id']], :joins=>[:entity])
  search_for(:paid_account, :account, :columns=>["number:X%", :name], :conditions => {:company_id=>['@current_company.id']})
  search_for(:purchase_products, :product, :columns=>[:code, :name], :conditions => {:company_id=>['@current_company.id'], :active=>true}, :order=>"name")
  search_for(:subscription_contacts, :contact, :columns=>['entity.code', 'entity.full_name', :address], :joins=>[:entity], :conditions=>["#{Contact.table_name}.company_id=? AND deleted_at IS NULL", ['@current_company.id']])
  search_for(:suppliers_accounts, :accounts, :columns=>[:number, :name], :conditions=>["company_id=? AND number LIKE ?", ["@current_company.id"], ["@current_company.preferred_third_suppliers_accounts.to_s+'%'"]])
  search_for(:suppliers, :entities, :columns=>[:code, :full_name], :conditions => {:company_id=>['@current_company.id'], :supplier=>true}, :order=>"active DESC, last_name, first_name")

  autocomplete_for(:entity, :origin)
  autocomplete_for(:event, :location)
  autocomplete_for(:mandate, :family)
  autocomplete_for(:mandate, :organization)
  autocomplete_for(:mandate, :title)
  autocomplete_for(:area, :name)
end
