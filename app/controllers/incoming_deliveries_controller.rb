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

class IncomingDeliveriesController < ApplicationController

  list(:conditions=>moved_conditions(IncomingDelivery)) do |t|
    t.column :number
    t.column :reference_number
    t.column :comment
    t.column :weight
    t.column :planned_on
    t.column :moved_on
    t.column :name, :through=>:mode
    t.column :number, :through=>:purchase, :url=>true
    t.column :amount
    t.action :confirm, :method=>:post, :if=>'RECORD.moved_on.nil? ', :confirm=>:are_you_sure
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  # Displays the main page with the list of incoming deliveries
  def index
  end

  def confirm
    return unless incoming_delivery = find_and_check(:incoming_delivery)
    incoming_delivery.execute if request.post?
    redirect_to :action=>:index, :mode=>:unconfirmed
  end

  def new
    return unless @purchase = find_and_check(:purchase, params[:purchase_id]||params[:purchase_id]||session[:current_purchase_id])
    unless @purchase.order?
      notify_warning(:purchase_already_invoiced)
      redirect_to_back
      return
    end
    purchase_lines = @purchase.lines# .find_all_by_reduction_origin_id(nil)
    notify_warning(:no_lines_found) if purchase_lines.empty?
    @incoming_delivery = IncomingDelivery.new(:pretax_amount=>@purchase.undelivered("pretax_amount"), :amount=>@purchase.undelivered("amount"), :planned_on=>Date.today, :contact_id=>@purchase.delivery_contact_id)      
    @incoming_delivery_lines = purchase_lines.collect{|x| IncomingDeliveryLine.new(:purchase_line_id=>x.id, :quantity=>x.undelivered_quantity)}
    render_restfully_form
  end

  def create
    return unless @purchase = find_and_check(:purchase, params[:purchase_id]||params[:purchase_id]||session[:current_purchase_id])
    unless @purchase.order?
      notify_warning(:purchase_already_invoiced)
      redirect_to_back
    end
    purchase_lines = @purchase.lines# .find_all_by_reduction_origin_id(nil)
    notify_warning(:no_lines_found) if purchase_lines.empty?

    @incoming_delivery = @purchase.deliveries.new(params[:incoming_delivery])
    ActiveRecord::Base.transaction do
      if saved = @incoming_delivery.save
        for line in purchase_lines
          if params[:incoming_delivery_line][line.id.to_s][:quantity].to_f > 0
            incoming_delivery_line = @incoming_delivery.lines.new(:purchase_line_id=>line.id, :quantity=>params[:incoming_delivery_line][line.id.to_s][:quantity].to_f)
            saved = false unless incoming_delivery_line.save
            @incoming_delivery.errors.add_from_record(incoming_delivery_line)
          end
        end
      end
      raise ActiveRecord::Rollback unless saved  
      redirect_to :controller=>:purchases, :action=>:show, :step=>:deliveries, :id=>@purchase.id
      return
    end
    @incoming_delivery_lines = purchase_lines.collect{|x| IncomingDeliveryLine.new(:purchase_line_id=>x.id, :quantity=>x.undelivered_quantity)}
    render_restfully_form
  end

  def edit
    return unless @incoming_delivery = find_and_check(:incoming_delivery)
    session[:current_incoming_delivery] = @incoming_delivery.id
    @purchase = @incoming_delivery.purchase
    # return unless @purchase = find_and_check(:purchases, session[:current_purchase_id])
    # purchase_lines = PurchaseLine.find(:all,:conditions=>{:company_id=>@current_company.id, :purchase_id=>session[:current_purchase_id]})
    # @incoming_delivery_lines = IncomingDeliveryLine.find(:all,:conditions=>{:company_id=>@current_company.id, :incoming_delivery_id=>@incoming_delivery.id})
    @incoming_delivery_lines = @incoming_delivery.lines
    render_restfully_form(:id=>@incoming_delivery_form)
  end

  def update
    return unless @incoming_delivery = find_and_check(:incoming_delivery)
    session[:current_incoming_delivery] = @incoming_delivery.id
    @purchase = @incoming_delivery.purchase
    # return unless @purchase = find_and_check(:purchases, session[:current_purchase_id])
    # purchase_lines = PurchaseLine.find(:all,:conditions=>{:company_id=>@current_company.id, :purchase_id=>session[:current_purchase_id]})
    # @incoming_delivery_lines = IncomingDeliveryLine.find(:all,:conditions=>{:company_id=>@current_company.id, :incoming_delivery_id=>@incoming_delivery.id})
    @incoming_delivery_lines = @incoming_delivery.lines
    ActiveRecord::Base.transaction do
      saved = @incoming_delivery.update_attributes!(params[:incoming_delivery])
      if saved and params[:incoming_delivery_line]
        for line in @incoming_delivery.lines
          line_attrs = params[:incoming_delivery_line][line.purchase_line.id.to_s]||{}
          if line_attrs[:quantity].to_f > 0
            saved = false unless line.update_attributes(:quantity=>line_attrs[:quantity].to_f)
            @incoming_delivery.errors.add_from_record(line)
          end
        end
      end
      if saved
        redirect_to :controller=>:purchases, :action=>:show, :step=>:deliveries, :id=>@purchase.id
        return
      else
        raise ActiveRecord::Rollback
      end
    end
    render_restfully_form(:id=>@incoming_delivery_form)
  end


  def destroy
    return unless @incoming_delivery = find_and_check(:incoming_delivery)
    @incoming_delivery.destroy if @incoming_delivery.destroyable?
    redirect_to_current
  end

end
