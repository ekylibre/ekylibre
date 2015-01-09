# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::SubscriptionsController < BackendController
  manage_restfully except: [:index], address_id: "EntityAddress.find_by(entity_id: params[:subscriber_id]).id rescue 0".c, nature_id: "SubscriptionNature.first.id rescue 0".c, t3e: {nature: "@subscription.nature.name".c, start: "@subscription.start".c, finish: "@subscription.finish".c}

  unroll

  def self.subscriptions_conditions(options={})
    code  = ""
    code << "conditions = [ \" COALESCE(#{Subscription.table_name}.sale_id, 0) NOT IN (SELECT id FROM #{Sale.table_name} WHERE state NOT IN ('invoice', 'order'))\" ]\n"
    code << "unless session[:subscriptions_nature_id].to_i.zero?\n"
    code << "  conditions[0] += \" AND #{Subscription.table_name}.nature_id = ?\"\n"
    code << "  conditions << session[:subscriptions_nature_id].to_i\n"
    code << "end\n"
    code << "unless session[:subscriptions_instant].nil?\n"
    code << "  if session[:subscriptions_nature_nature] == 'quantity'\n"
    code << "    conditions[0] += \" AND ? BETWEEN #{Subscription.table_name}.first_number AND #{Subscription.table_name}.last_number\"\n"
    code << "    conditions << session[:subscriptions_instant]\n"
    code << "  elsif session[:subscriptions_nature_nature] == 'period'\n"
    code << "    conditions[0] += \" AND ? BETWEEN #{Subscription.table_name}.started_at AND #{Subscription.table_name}.stopped_at\"\n"
    code << "    conditions << session[:subscriptions_instant]\n"
    code << "  end\n"
    code << "end\n"
    code << "conditions\n"
    return code.c
  end

  list(conditions: subscriptions_conditions, order: {id: :desc}) do |t|
    t.column :mail_line_1, through: :address, url: true
    t.column :mail_line_2, through: :address, :label => :column
    t.column :mail_line_3, through: :address, :label => :column
    t.column :mail_line_4, through: :address, :label => :column
    t.column :mail_line_5, through: :address, :label => :column
    t.column :mail_line_6, through: :address, :label => :column
    t.column :product_nature
    t.column :quantity
    t.column :start
    t.column :finish
  end

  # Displays the main page with the list of subscriptions
  def index
    if SubscriptionNature.count.zero?
      notify(:need_to_create_subscription_nature)
      redirect_to controller: :subscription_natures
      return
    end
    if request.xhr?
      return unless @subscription_nature = find_and_check(:subscription_nature, params[:nature_id])
      session[:subscriptions_instant] = @subscription_nature.now
      render :partial => "options"
      return
    end
    if params[:nature_id]
      return unless @subscription_nature = find_and_check(:subscription_nature, params[:nature_id])
    end
    @subscription_nature ||= SubscriptionNature.first
    instant = (@subscription_nature.period? ? params[:instant].to_date : params[:instant].to_i) rescue nil
    session[:subscriptions_nature_id]  = @subscription_nature.id
    session[:subscriptions_nature_nature] = @subscription_nature.nature.to_sym
    session[:subscriptions_instant] = ((instant.blank? or instant == 0) ? @subscription_nature.now : instant)
  end


  # def coordinates
  #   nature, attributes = nil, {}
  #   if params[:nature_id]
  #     return unless nature = find_and_check(:subscription_nature, params[:nature_id])
  #   elsif params[:price_id]
  #     return unless price = find_and_check(:product_price_template, params[:price_id])
  #     if price.product_nature.subscribing?
  #       nature = price.product_nature.subscription_nature
  #       attributes[:product_nature_id] = price.product_nature_id
  #     end
  #   end
  #   if nature
  #     attributes[:address_id] = (EntityAddress.find_by_entity_id(params[:subscriber_id]).id rescue 0)
  #     @subscription = nature.subscriptions.new(attributes)
  #     @subscription.compute_period
  #   end
  #   mode = params[:mode]||:coordinates
  #   render :partial => "#{mode}_form"
  # end

end
