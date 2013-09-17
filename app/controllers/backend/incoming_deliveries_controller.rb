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

class Backend::IncomingDeliveriesController < BackendController
  unroll

  manage_restfully

  respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

  list do |t|
    t.column :number, :url => true
    t.column :reference_number
    # t.column :description
    # t.column :weight
    t.column :received_at
    t.column :name, :through => :mode
    t.column :number, :through => :purchase, :url => true
    # t.action :confirm, :method => :post, :if => :confirmable?, 'data-confirm'  =>  :are_you_sure
    t.action :edit
    t.action :destroy
  end

  # Liste des items d'une appro
  list(:item, :model => :incoming_delivery_items, :conditions => [" delivery_id = ? ",['session[:current_incoming_delivery_id]']], :order => "created_at DESC") do |t|
    t.column :name, :through => :product, :url => true
    t.column :quantity
    t.column :name, :through => :purchase_item, :url => true
    t.column :created_at
  end

  # Displays the main page with the list of incoming deliveries
  def index
  end

  def show
    return unless @incoming_delivery = find_and_check
    session[:current_incoming_delivery_id] = @incoming_delivery.id
    t3e @incoming_delivery, :number => @incoming_delivery.number
    respond_with(@incoming_delivery, :methods => :picture_path, :include => [:address, :mode, :purchase, :sender])
  end

  def confirm
    return unless incoming_delivery = find_and_check
    incoming_delivery.execute if request.post?
    redirect_to :action => :index, :mode => :unconfirmed
  end

  # def new
  #   return unless @purchase = find_and_check(:purchase, params[:purchase_id]||params[:purchase_id]||session[:current_purchase_id])
  #   unless @purchase.order?
  #     notify_warning(:purchase_already_invoiced)
  #     redirect_to_back
  #     return
  #   end
  #   purchase_items = @purchase.items # .find_all_by_reduction_origin_id(nil)
  #   notify_warning(:no_items_found) if purchase_items.empty?
  #   @incoming_delivery = IncomingDelivery.new({:pretax_amount => @purchase.undelivered("pretax_amount"), :amount => @purchase.undelivered("amount"), :planned_at => Date.today, :address_id => @purchase.delivery_address_id}, :without_protection => true)
  #   @incoming_delivery_items = purchase_items.collect{|x| IncomingDeliveryItem.new(:purchase_item_id => x.id, :quantity => x.undelivered_quantity)}
  #   # render_restfully_form
  # end

  # def create
  #   return unless @purchase = find_and_check(:purchase, params[:purchase_id]||params[:purchase_id]||session[:current_purchase_id])
  #   unless @purchase.order?
  #     notify_warning(:purchase_already_invoiced)
  #     redirect_to_back
  #   end
  #   purchase_items = @purchase.items# .find_all_by_reduction_origin_id(nil)
  #   notify_warning(:no_items_found) if purchase_items.empty?

  #   @incoming_delivery = @purchase.deliveries.new(params[:incoming_delivery])
  #   ActiveRecord::Base.transaction do
  #     if saved = @incoming_delivery.save
  #       for item in purchase_items
  #         if params[:incoming_delivery_item][item.id.to_s][:quantity].to_f > 0
  #           incoming_delivery_item = @incoming_delivery.items.new(:purchase_item_id => item.id, :quantity => params[:incoming_delivery_item][item.id.to_s][:quantity].to_f)
  #           saved = false unless incoming_delivery_item.save
  #           @incoming_delivery.errors.add_from_record(incoming_delivery_item)
  #         end
  #       end
  #     end
  #     raise ActiveRecord::Rollback unless saved
  #     redirect_to :controller => :purchases, :action => :show, :step => :deliveries, :id => @purchase.id
  #     return
  #   end
  #   @incoming_delivery_items = purchase_items.collect{|x| IncomingDeliveryItem.new(:purchase_item_id => x.id, :quantity => x.undelivered_quantity)}
  #   # render_restfully_form
  # end

  # def edit
  #   return unless @incoming_delivery = find_and_check(:incoming_delivery)
  #   session[:current_incoming_delivery] = @incoming_delivery.id
  #   @purchase = @incoming_delivery.purchase
  #   @incoming_delivery_items = @incoming_delivery.items
  #   # render_restfully_form(:id => @incoming_delivery_form)
  # end

  # def update
  #   return unless @incoming_delivery = find_and_check(:incoming_delivery)
  #   session[:current_incoming_delivery] = @incoming_delivery.id
  #   @purchase = @incoming_delivery.purchase
  #   @incoming_delivery_items = @incoming_delivery.items
  #   ActiveRecord::Base.transaction do
  #     saved = @incoming_delivery.update_attributes!(params[:incoming_delivery])
  #     if saved and params[:incoming_delivery_item]
  #       for item in @incoming_delivery.items
  #         item_attrs = params[:incoming_delivery_item][item.purchase_item.id.to_s]||{}
  #         if item_attrs[:quantity].to_f > 0
  #           saved = false unless item.update_attributes(:quantity => item_attrs[:quantity].to_f)
  #           @incoming_delivery.errors.add_from_record(item)
  #         end
  #       end
  #     end
  #     if saved
  #       redirect_to :controller => :purchases, :action => :show, :step => :deliveries, :id => @purchase.id
  #       return
  #     else
  #       raise ActiveRecord::Rollback
  #     end
  #   end
  #   # render_restfully_form(:id => @incoming_delivery_form)
  # end

  # def destroy
  #   return unless @incoming_delivery = find_and_check(:incoming_delivery)
  #   @incoming_delivery.destroy if @incoming_delivery.destroyable?
  #   redirect_to_current
  # end

end
