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

class Backend::InterfacersController < BackendController

  # Saves the state of the side bar
  def toggle_side
    # Explicit conversion
    session[:side] = (params[:splitted] == "1" ? false : true)
    render :text => ''
  end

  # Saves the state of the side bar
  def toggle_module
    # Explicit conversion
    shown = (params[:shown].to_i>0 ? true : false)
    session[:modules] ||= {}
    session[:modules][params[:module]] = shown
    @current_user.preference("interface.show_modules.#{params[:module]}", true, :boolean).set(shown)
    render :text => ''
  end

  # Saves the last selected tab in a tabbox
  def toggle_tab
    session[:tabbox] ||= {}
    session[:tabbox][params['id']] = params['index']
    render :text => nil
  end

  # Saves the view mode
  def toggle_view_mode
    session[:view_mode] = params[:mode]
    render :text => ''
  end

  # TODO: Manage options in role and add watch dog to ensure that autocomplete must be used in rights with parameters
  def autocomplete

  end

  def select_options
    options = [:source, :filter, :model, :id, :label, :include_blank, :selected].inject({}) do |hash, key|
      hash[key] = params[key] if params.has_key?(key)
      hash
    end
    respond_to do |format|
      format.html { render :inline => '<%=options_for_unroll(@options)-%>' }
    end
  end

  def search_for
  end



  def unroll
    @options = [:source, :filter, :model, :id, :label, :include_blank, :selected].inject({}) do |hash, key|
      hash[key] = params[key] if params.has_key?(key)
      hash
    end
    render :inline => '<%=options_for_unroll(@options)-%>'
  end


  # Returns the new list for a "dynamic select" using helper options_for_unroll
  def unroll_options
    @options = {}
    for x in [:reflection, :order, :label, :include_blank]
      @options[x] = params[x]
    end
    render :inline => '<%=options_for_select(options_for_unroll(@options), params[:selected].to_i)-%>'
  end

  def product_trackings
    return unless @product = find_and_check(:product_natures, params[:product_id])
    render :inline => "<%=options_for_select([['---', '']]+@product.trackings.collect{|x| [x.name, x.id]})-%>", :layout => false
  end

  def product_units
    return unless @product = find_and_check(:product_natures, params[:product_id])
    render :inline => "<%=options_for_select(@product.units.collect{|x| [x.name, x.id]})-%>", :layout => false
  end


  def self.available_prices_conditions
    code = ""
    code << "c=['#{Price.table_name}.active=? AND #{ProductNature.table_name}.active=?', true, true]\n"
    code << "if session[:current_currency]\n"
    code << "  c[0] << ' AND currency=?'\n"
    code << "  c << session[:current_currency]\n"
    code << "end\n"
    return code
  end


  # search_for(:account, :columns => ["number:X%", :name])
  # search_for(:all_contacts, :contacts, :columns => [:address], :conditions  => ["deleted_at IS NULL"])
  # search_for(:attorneys_accounts, :accounts, :columns => [:number, :name], :conditions => [" number LIKE ?", ["Account.find_in_chart(:attorney_thirds).number.to_s+'%'"]])
  # search_for(:available_prices, :prices, :columns => ["product.code", "product.name", {:name => :pretax_amount, :code => "I18n.localize(DATUM, :currency => RECORD.currency)"}, {:name => :amount, :code => "I18n.localize(DATUM, :currency => RECORD.currency)"}], :joins => [:product], :conditions => available_prices_conditions, :order => "products.name, prices.amount")
  # search_for(:clients_accounts, :accounts, :columns => [:number, :name], :conditions => ["number LIKE ?", ["Account.find_in_chart(:client_thirds).number.to_s+'%'"]])
  # search_for(:client_contacts, :contacts, :columns => [:address], :conditions => ["entity_id = ? AND deleted_at IS NULL", ['session[:current_entity_id]']])
  # # Saves the state of the side bar
  # def toggle_side
  #   # Explicit conversion
  #   session[:side] = (params[:splitted] == "1" ? false : true)
  #   render :text => ''
  # end

  # # Saves the state of the side bar
  # def toggle_module
  #   # Explicit conversion
  #   shown = (params[:shown].to_i>0 ? true : false)
  #   session[:modules] ||= {}
  #   session[:modules][params[:module]] = shown
  #   @current_user.preference("interface.show_modules.#{params[:module]}", true, :boolean).set(shown)
  #   render :text => ''
  # end

  # # Saves the last selected tab in a tabbox
  # def toggle_tab
  #   session[:tabbox] ||= {}
  #   session[:tabbox][params['id']] = params['index']
  #   render :text => nil
  # end

  # # Saves the view mode
  # def toggle_view_mode
  #   session[:view_mode] = params[:mode]
  #   render :text => ''
  # end

  # # TODO: Manage options in role and add watch dog to ensure that autocomplete must be used in rights with parameters
  # def autocomplete

  # end

  # def select_options
  #   options = [:source, :filter, :model, :id, :label, :include_blank, :selected].inject({}) do |hash, key|
  #     hash[key] = params[key] if params.has_key?(key)
  #     hash
  #   end
  #   respond_to do |format|
  #     format.html { render :inline => '<%=options_for_unroll(@options)-%>' }
  #   end
  # end

  # def search_for
  # end



  # def unroll
  #   @options = [:source, :filter, :model, :id, :label, :include_blank, :selected].inject({}) do |hash, key|
  #     hash[key] = params[key] if params.has_key?(key)
  #     hash
  #   end
  #   render :inline => '<%=options_for_unroll(@options)-%>'
  # end


  # # Returns the new list for a "dynamic select" using helper options_for_unroll
  # def unroll_options
  #   @options = {}
  #   for x in [:reflection, :order, :label, :include_blank]
  #     @options[x] = params[x]
  #   end
  #   render :inline => '<%=options_for_select(options_for_unroll(@options), params[:selected].to_i)-%>'
  # end

  # def product_trackings
  #   return unless @product = find_and_check(:product, params[:product_id])
  #   render :inline => "<%=options_for_select([['---', '']]+@product.trackings.collect{|x| [x.name, x.id]})-%>", :layout => false
  # end

  # def product_units
  #   return unless @product = find_and_check(:product, params[:product_id])
  #   render :inline => "<%=options_for_select(@product.units.collect{|x| [x.name, x.id]})-%>", :layout => false
  # end


  # def self.available_prices_conditions
  #   code = ""
  #   code << "c=['#{Price.table_name}.active=? AND #{Product.table_name}.active=?', true, true]\n"
  #   code << "if session[:current_currency]\n"
  #   code << "  c[0] << ' AND currency=?'\n"
  #   code << "  c << session[:current_currency]\n"
  #   code << "end\n"
  #   return code
  # end


  # search_for(:account, :columns => ["number:X%", :name])
  # # search_for(:all_addresses, :addresses, :columns => [:address], :conditions  => ["deleted_at IS NULL"])
  # search_for(:attorneys_accounts, :accounts, :columns => [:number, :name], :conditions => [" number LIKE ?", ["Account.find_in_chart(:attorney_thirds).number.to_s+'%'"]])
  # search_for(:available_prices, :prices, :columns => ["product.code", "product.name", {:name => :pretax_amount, :code => "I18n.localize(DATUM, :currency => RECORD.currency)"}, {:name => :amount, :code => "I18n.localize(DATUM, :currency => RECORD.currency)"}], :joins => [:product], :conditions => available_prices_conditions, :order => "products.name, prices.amount")
  # search_for(:clients_accounts, :accounts, :columns => [:number, :name], :conditions => ["number LIKE ?", ["Account.find_in_chart(:client_thirds).number.to_s+'%'"]])
  # # search_for(:client_addresses, :addresses, :columns => [:address], :conditions => ["entity_id = ? AND deleted_at IS NULL", ['session[:current_entity_id]']])

  # search_for(:clients, :entities, :columns => [:code, :full_name], :conditions => {:client => true})
  # search_for(:collected_account, :account, :columns => ["number:X%", :name])
  # search_for(:districts, :columns => [:name, :code])
  # search_for(:entities, :columns => [:code, :full_name])

  # search_for(:incoming_delivery_contacts, :contact, :columns => ['entity.full_name', :address], :conditions  => ["#{Contact.table_name}.deleted_at IS NULL AND entity.of_company"], :joins => [:entities])
  # search_for(:operation_products, :product, :columns => [:code, :name], :conditions  => {:active => true})
  # search_for(:outgoing_deliveries, :columns => [:planned_on, "contact.address"], :conditions => ["transport_id IS NULL"], :joins => [:contact])
  # search_for(:outgoing_delivery_contacts, :contacts, :columns => ['entity.full_name', :address], :conditions => ["#{Contact.table_name}.deleted_at IS NULL"], :joins => [:entity])
  # search_for(:paid_account, :account, :columns => ["number:X%", :name])
  # search_for(:purchase_products, :product, :columns => [:code, :name], :conditions => {:active => true}, :order => "name")
  # search_for(:subscription_contacts, :contact, :columns => ['entity.code', 'entity.full_name', :address], :joins => [:entity], :conditions => ["deleted_at IS NULL"])

  # # search_for(:incoming_delivery_addresses, :address, :columns => ['entity.full_name', :address], :conditions  => ["#{EntityAddress.table_name}.deleted_at IS NULL AND entity.of_company"], :joins => [:entities])
  # search_for(:operation_products, :product, :columns => [:code, :name], :conditions  => {:active => true})
  # # search_for(:outgoing_deliveries, :columns => [:planned_on, "address.address"], :conditions => ["transport_id IS NULL"], :joins => [:address])
  # # search_for(:outgoing_delivery_addresses, :addresses, :columns => ['entity.full_name', :address], :conditions => ["#{EntityAddress.table_name}.deleted_at IS NULL"], :joins => [:entity])
  # search_for(:paid_account, :account, :columns => ["number:X%", :name])
  # search_for(:purchase_products, :product, :columns => [:code, :name], :conditions => {:active => true}, :order => "name")
  # # search_for(:subscription_addresses, :address, :columns => ['entity.code', 'entity.full_name', :address], :joins => [:entity], :conditions => ["deleted_at IS NULL"])
  # search_for(:suppliers_accounts, :accounts, :columns => [:number, :name], :conditions => ["number LIKE ?", ["Account.find_in_chart(:supplier_thirds).number.to_s+'%'"]])
  # search_for(:suppliers, :entities, :columns => [:code, :full_name], :conditions => {:supplier => true}, :order => "active DESC, last_name, first_name")

  autocomplete_for(:entity, :origin)
  autocomplete_for(:event, :location)
  autocomplete_for(:mandate, :family)
  autocomplete_for(:mandate, :organization)
  autocomplete_for(:mandate, :title)
  autocomplete_for(:area, :name)
end
