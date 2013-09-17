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

class Backend::OutgoingDeliveriesController < BackendController

  unroll

  list(:conditions => light_search_conditions(:outgoing_deliveries => [:number, :reference_number, :weight, :amount, :pretax_amount], :entities => [:full_name, :code])+shipping_conditions(OutgoingDelivery)) do |t|
    t.column :number, :url => true
    t.column :number, :through => :transport, :url => true
    t.column :full_name, :through => :transporter, :url => true
    t.column :reference_number
    t.column :description
    t.column :planned_at
    #t.column :moved_on
    t.column :name, :through => :mode
    # t.column :number, :through => :sale, :url => true
    #t.column :weight
    #t.column :amount
    t.action :edit
    t.action :destroy
  end

  # Displays the main page with the list of outgoing deliveries
  def index
  end

  list(:items, :model => :outgoing_delivery_items, :conditions => {:delivery_id => ['session[:current_outgoing_delivery_id]']}) do |t|
    t.column :name, :through => :product, :url => true
    t.column :serial_number, :through => :product
    t.column :quantity
    t.column :unit
    t.column :pretax_amount
    t.column :amount
    # t.column :name, :through => :building, :url => true
  end

  # Displays details of one outgoind delivery selected with +params[:id]+
  def show
    return unless @outgoing_delivery = find_and_check(:outgoing_delivery)
    session[:current_outgoing_delivery_id] = @outgoing_delivery.id
    t3e @outgoing_delivery.attributes
  end

  def new
    return unless sale = find_and_check(:sale, params[:sale_id])
    unless sale.deliverable?
      notify_warning(:sale_already_invoiced)
      redirect_to_back
      return
    end
    sale_items = sale.items.where(:reduction_origin_id => nil)
    notify_warning(:no_items_found) if sale_items.empty?

    @outgoing_delivery_items = sale_items.collect{|x| OutgoingDeliveryItem.new(:sale_item_id => x.id, :quantity => x.undelivered_quantity)}
    @outgoing_delivery = sale.deliveries.build({:pretax_amount => sale.undelivered(:pretax_amount), :amount => sale.undelivered(:amount), :planned_at => Date.today, :transporter_id => sale.transporter_id, :address => sale.delivery_address||sale.client.default_mail_address}, :without_protection => true)
    # render_restfully_form
  end

  def create
    return unless sale = find_and_check(:sales, params[:sale_id]||params[:sale_id]||session[:current_sale_id])
    unless sale.deliverable?
      notify_warning(:sale_already_invoiced)
      redirect_to_back
      return
    end
    sale_items = sale.items.where(:reduction_origin_id => nil)
    notify_warning(:no_items_found) if sale_items.empty?
    @outgoing_delivery_items = []
    @outgoing_delivery = sale.deliveries.new(params[:outgoing_delivery])
    ActiveRecord::Base.transaction do
      if saved = @outgoing_delivery.save
        puts [saved, @outgoing_delivery.errors].inspect

        for item in sale_items
          quantity = params[:outgoing_delivery_item][item.id.to_s][:quantity].to_f rescue 0
          outgoing_delivery_item = @outgoing_delivery.items.new(:sale_item_id => item.id, :quantity => quantity)
          if quantity > 0
            saved = false unless outgoing_delivery_item.save
            puts [saved, outgoing_delivery_item, outgoing_delivery_item.errors.to_hash].inspect
            @outgoing_delivery.errors.add_from_record(outgoing_delivery_item)
          end
          @outgoing_delivery_items << outgoing_delivery_item
        end if params[:outgoing_delivery_item].is_a? Hash
      end
      if saved
        redirect_to_back
        return
      end
      raise ActiveRecord::Rollback unless saved
    end
    # render_restfully_form
  end

  def edit
    return unless @outgoing_delivery = find_and_check(:outgoing_delivery)
    session[:current_outgoing_delivery] = @outgoing_delivery.id
    @outgoing_delivery_items = @outgoing_delivery.items
    t3e @outgoing_delivery.attributes
    # render_restfully_form
  end

  def update
    return unless @outgoing_delivery = find_and_check(:outgoing_delivery)
    session[:current_outgoing_delivery] = @outgoing_delivery.id
    @outgoing_delivery_items = @outgoing_delivery.items
    ActiveRecord::Base.transaction do
      saved = @outgoing_delivery.update_attributes!(params[:outgoing_delivery])
      if saved
        for item in @outgoing_delivery.items
          saved = false unless item.update_attributes(:quantity => params[:outgoing_delivery_item][item.sale_item.id.to_s][:quantity])
          @outgoing_delivery.errors.add_from_record(item)
        end
      end
      if saved
        redirect_to_back
        return
      end
      raise ActiveRecord::Rollback unless saved
    end
    t3e @outgoing_delivery.attributes
    # render_restfully_form
  end

  def destroy
    return unless @outgoing_delivery = find_and_check(:outgoing_delivery)
    @outgoing_delivery.destroy
    redirect_to_current
  end

end
