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

class SubscriptionsController < ApplicationController
  manage_restfully :contact_id=>"@current_company.contacts.find_by_entity_id(params[:entity_id]).id rescue 0", :entity_id=>"@current_company.entities.find(params[:entity_id]).id rescue 0", :nature_id=>"@current_company.subscription_natures.first.id rescue 0", :t3e=>{:nature=>"@subscription.nature.name", :start=>"@subscription.start", :finish=>"@subscription.finish"}

  list(:conditions=>subscriptions_conditions, :order=> "id DESC") do |t|
    t.column :full_name, :through=>:entity, :url=>true
    t.column :line_2, :through=>:contact, :label=>:column
    t.column :line_3, :through=>:contact, :label=>:column
    t.column :line_4, :through=>:contact, :label=>:column
    t.column :line_5, :through=>:contact, :label=>:column
    t.column :line_6_code, :through=>:contact, :label=>:column
    t.column :line_6_city, :through=>:contact, :label=>:column
    t.column :name, :through=>:product
    t.column :quantity
    #t.column :started_on
    #t.column :finished_on
    #t.column :first_number
    #t.column :last_number
    t.column :start
    t.column :finish
  end

  def coordinates
    nature, attributes = nil, {}
    if params[:nature_id]
      return unless nature = find_and_check(:subscription_nature, params[:nature_id])
    elsif params[:price_id]
      return unless price = find_and_check(:price, params[:price_id])
      if price.product.subscription?
        nature = price.product.subscription_nature 
        attributes[:product_id] = price.product_id
      end
    end
    if nature
      attributes[:contact_id] = (@current_company.contacts.find_by_entity_id(params[:entity_id]).id rescue 0)
      @subscription = nature.subscriptions.new(attributes)
      @subscription.compute_period
    end
    mode = params[:mode]||:coordinates
    render :partial=>"#{mode}_form"
  end

  def message
    return unless price = find_and_check(:prices, params[:sale_line_price_id])
    @product = price.product
  end

  # Displays the main page with the list of subscriptions
  def index
    if @current_company.subscription_natures.size == 0
      notify(:need_to_create_subscription_nature)
      redirect_to subscription_natures_url
      return
    end

    if request.xhr?
      return unless @subscription_nature = find_and_check(:subscription_nature, params[:nature_id])
      session[:subscriptions][:instant] = @subscription_nature.now
      render :partial=>"options"
      return
    else
      if params[:nature_id]
        return unless @subscription_nature = find_and_check(:subscription_nature, params[:nature_id])
      end
      @subscription_nature ||= @current_company.subscription_natures.first
      instant = (@subscription_nature.period? ? params[:instant].to_date : params[:instant]) rescue nil 
      session[:subscriptions] ||= {}
      session[:subscriptions][:nature]  = @subscription_nature.attributes
      session[:subscriptions][:instant] = (instant.blank? ? @subscription_nature.now : instant)
    end
  end

end
