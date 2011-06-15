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
  
  # Saves the last selected tab in a tabbox
  def toggle_tab
    session[:tabbox] ||= {}
    session[:tabbox][params['id']] = params['index']
    render :text=>nil
  end

  # Returns the new list for a "dynamic select" using company's reflections
  def formalize
    @options = {}
    for x in [:reflection, :order, :label, :include_blank]
      @options[x] = params[x]
    end
    render :inline=>'<%=options_for_select(@current_company.reflection_options(@options), params[:selected].to_i)-%>'
  end


  dyli(:account, ["number:X%", :name], :conditions =>{:company_id=>['@current_company.id']})
  # dyli(:account, ["number:X%", :name], :conditions => {:company_id=>['@current_company.id']})
  dyli(:all_contacts, [:address], :model=>:contacts, :conditions => {:company_id=>['@current_company.id'], :active=>true})
  dyli(:attorneys_accounts, [:number, :name], :model=>:accounts, :conditions=>["company_id=? AND number LIKE ?", ["@current_company.id"], ["@current_company.preferred_third_attorneys_accounts.to_s+'%'"]])
  dyli(:available_prices, ["products.code", "products.name", "prices.pretax_amount", "prices.amount"], :model=>:prices, :joins=>"JOIN #{Product.table_name} AS products ON (product_id=products.id)", :conditions=>["prices.company_id=? AND prices.active=? AND products.active=?", ['@current_company.id'], true, true], :order=>"products.name, prices.amount")
  dyli(:clients_accounts, [:number, :name], :model=>:accounts, :conditions=>["company_id=? AND number LIKE ?", ["@current_company.id"], ["@current_company.preferred_third_clients_accounts.to_s+'%'"]])
  dyli(:client_contacts, [:address] ,:model=>:contacts, :conditions=>["company_id = ? AND entity_id = ? AND deleted_at IS NULL", ['@current_company.id'], ['session[:current_entity_id]']])
  dyli(:clients, [:code, :full_name], :model=>:entities, :conditions => {:company_id=>['@current_company.id'], :client=>true})
  dyli(:collected_account, ["number:X%", :name], :model=>:account, :conditions => {:company_id=>['@current_company.id']})
  # dyli(:contacts, [:address], :conditions => { :company_id=>['@current_company.id'], :entity_id=>['@current_company.entity_id']})
  dyli(:districts, [:name, :code], :conditions=>{:company_id=>['@current_company.id']})
  dyli(:entities, [:code, :full_name], :conditions => {:company_id=>['@current_company.id']})
  # dyli(:entities, [:code, :full_name], :conditions => {:company_id=>['@current_company.id']})
  dyli(:incoming_delivery_contacts, ['entities.full_name', :address], :conditions => { :company_id=>['@current_company.id'], :active=>true}, :joins=>"JOIN #{Company.table_name} AS companies ON (companies.entity_id=#{Contact.table_name}.entity_id))", :model=>:contacts)
  dyli(:operation_products, [:code, :name], :model=>:products, :conditions => {:company_id=>['@current_company.id'], :active=>true})
  # dyli(:operation_out_products, [:code, :name], :model=>:products, :conditions => {:company_id=>['@current_company.id'], :active=>true, :to_produce=>true})
  dyli(:outgoing_deliveries, [:planned_on, "contacts.address"], :conditions=>["deliveries.company_id = ? AND transport_id IS NULL", ['@current_company.id']], :joins=>"INNER JOIN #{Contact.table_name} AS contacts ON contacts.id = deliveries.contact_id ")
  dyli(:outgoing_delivery_contacts, ['entities.full_name', :address], :conditions => { :company_id=>['@current_company.id'], :active=>true}, :joins=>"JOIN #{Entity.table_name} AS entities ON (entity_id=entities.id)", :model=>:contacts)
  dyli(:paid_account, ["number:X%", :name], :model=>:account, :conditions => {:company_id=>['@current_company.id']})
  dyli(:purchase_products, [:code, :name],  :model=>:products, :conditions => {:company_id=>['@current_company.id'], :active=>true}, :order=>"name")
  # dyli(:subscription_contacts,  [:address] ,:model=>:contact, :conditions=>{:entity_id=>['session[:current_entity_id]'], :active=>true, :company_id=>['@current_company.id']})
  dyli(:subscription_contacts,  ['entities.code', 'entities.full_name', :address] ,:model=>:contact, :joins=>"JOIN #{Entity.table_name} AS entities ON (entity_id=entities.id)", :conditions=>["entities.company_id=? AND deleted_at IS NULL", ['@current_company.id']])
  dyli(:suppliers_accounts, [:number, :name], :model=>:accounts, :conditions=>["company_id=? AND number LIKE ?", ["@current_company.id"], ["@current_company.preferred_third_suppliers_accounts.to_s+'%'"]])
  dyli(:suppliers, [:code, :full_name],  :model=>:entities, :conditions => {:company_id=>['@current_company.id'], :supplier=>true}, :order=>"active DESC, last_name, first_name")

  def auto_complete_for_contact_line_6
    if params[:contact] and request.xhr?
      pattern = '%'+params[:contact][:line_6].to_s.lower.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'
      @areas = @current_company.areas.find(:all, :conditions => [ 'LOWER(name) LIKE ? ', pattern], :order => "name ASC", :limit=>12)
      render :inline => "<%=content_tag(:ul, @areas.map { |area| content_tag(:li, h(area.name)) }.join.html_safe)%>"
    else
      render :text=>'', :layout=>true
    end
  end
  
  def auto_complete_for_entity_origin
    if params[:entity] and request.xhr?
      pattern = '%'+params[:entity][:origin].to_s.lower.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'
      @entities = @current_company.entities.find(:all, :conditions=> [ 'LOWER(origin) LIKE ?', pattern ], :order=>"origin ASC", :limit=>12)
      render :inline => "<%=content_tag(:ul, @entities.map { |entity| content_tag(:li, h(entity.origin)) }.join.html_safe)%>"
    else
      render :text=>'', :layout=>true
    end
  end

  def auto_complete_for_event_location
    if params[:event] and request.xhr?
      pattern = '%'+params[:event][:location].to_s.lower.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'
      @events = @current_company.events.find(:all, :conditions=> [ 'LOWER(location) LIKE ?', pattern ], :order=>"location ASC", :limit=>12)
      render :inline => "<%=content_tag(:ul, @events.map { |event| content_tag(:li, h(event.location)) }.join.html_safe)%>"
    else
      render :text=>'', :layout=>true
    end
  end

  def auto_complete_for_mandate
    if params[:columns] and request.xhr?
      column = params[:column]||'family'
      pattern = '%'+params[:columns][column][:search].to_s.lower.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'
      @mandates = @current_company.mandates.find(:all, :conditions => [ "LOWER(#{column}) LIKE ? ", pattern], :order=>column, :select => "DISTINCT #{column}")
      render :inline => "<%=content_tag(:ul, @mandates.map { |mandate| content_tag(:li, h(mandate.#{column})) }.join.html_safe)-%>"
    else
      render :text=>'', :layout=>true
    end
  end

  def auto_complete_for_mandate_family
    if params[:mandate] and request.xhr?
      pattern = '%'+params[:mandate][:family].to_s.lower.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'
      @mandates = @current_company.mandates.find(:all, :conditions => [ 'LOWER(family) LIKE ? ', pattern], :order => "family ASC", :select => 'DISTINCT family')
      render :inline => "<%=content_tag(:ul, @mandates.map { |mandate| content_tag(:li, h(mandate.family)) }.join.html_safe)%>"
    else
      render :text=>'', :layout=>true
    end
  end
  
  def auto_complete_for_mandate_organization
    if params[:mandate] and request.xhr?
      pattern = '%'+params[:mandate][:organization].to_s.lower.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'
      @mandates = @current_company.mandates.find(:all, :conditions => [ 'LOWER(organization) LIKE ? ', pattern], :order => "organization ASC", :select => 'DISTINCT organization')
      render :inline => "<%=content_tag(:ul, @mandates.map { |mandate| content_tag(:li, h(mandate.organization)) }.join.html_safe)%>"
    else
      render :text=>'', :layout=>true
    end
  end
  
  #
  def auto_complete_for_mandate_title
    if params[:mandate] and request.xhr?
      pattern = '%'+params[:mandate][:title].to_s.lower.strip.gsub(/\s+/,'%').gsub(/[#{String::MINUSCULES.join}]/,'_')+'%'
      @mandates = @current_company.mandates.find(:all, :conditions => [ 'LOWER(title) LIKE ? ', pattern], :order => "title ASC", :select => 'DISTINCT title')
      render :inline => "<%=content_tag(:ul, @mandates.map { |mandate| content_tag(:li, h(mandate.title)) }.join.html_safe)%>"
    else
      render :text=>'', :layout=>true
    end
  end


  def product_trackings
    return unless @product = find_and_check(:product)
    render :inline=>"<%=options_for_select([['---', '']]+@product.trackings.collect{|x| [x.name, x.id]})-%>"
  end

  def product_units
    return unless @product = find_and_check(:product)
    render :inline=>"<%=options_for_select(@product.units.collect{|x| [x.name, x.id]})-%>"
  end



  
end
