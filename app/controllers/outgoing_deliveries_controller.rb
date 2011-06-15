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

class OutgoingDeliveriesController < ApplicationController

  list(:conditions=>moved_conditions(OutgoingDelivery)) do |t|
    t.column :number
    t.column :reference_number
    t.column :comment
    t.column :weight
    t.column :planned_on
    t.column :moved_on
    t.column :name, :through=>:mode
    t.column :number, :through=>:sale, :url=>true
    t.column :amount
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  # Displays the main page with the list of outgoing deliveries
  def index
  end

  def new
    return unless @sale = find_and_check(:sales, params[:sale_id]||params[:sale_id]||session[:current_sale_id])
    unless @sale.order?
      notify(:sale_already_invoiced, :warning)
      redirect_to_back
    end
    sale_lines = @sale.lines.find_all_by_reduction_origin_id(nil)
    notify(:no_lines_found, :warning) if sale_lines.empty?

    @outgoing_delivery_lines = sale_lines.collect{|x| OutgoingDeliveryLine.new(:sale_line_id=>x.id, :quantity=>x.undelivered_quantity)}
    @outgoing_delivery = OutgoingDelivery.new(:pretax_amount=>@sale.undelivered("pretax_amount"), :amount=>@sale.undelivered("amount"), :planned_on=>Date.today, :transporter_id=>@sale.transporter_id, :contact_id=>@sale.delivery_contact_id||@sale.client.default_contact)
    # session[:current_outgoing_delivery] = @outgoing_delivery.id
  
    if request.post?
      @outgoing_delivery = @sale.deliveries.new(params[:outgoing_delivery])
      
      ActiveRecord::Base.transaction do
        if saved = @outgoing_delivery.save
          for line in sale_lines
            if params[:outgoing_delivery_line][line.id.to_s][:quantity].to_f > 0
              outgoing_delivery_line = @outgoing_delivery.lines.new(:sale_line_id=>line.id, :quantity=>params[:outgoing_delivery_line][line.id.to_s][:quantity].to_f)
              saved = false unless outgoing_delivery_line.save
              @outgoing_delivery.errors.add_from_record(outgoing_delivery_line)
            end
          end
        end
        raise ActiveRecord::Rollback unless saved  
        redirect_to :action=>:sale, :step=>:deliveries, :id=>session[:current_sale_id] 
      end
    end
    render_restfully_form(:id=>@outgoing_delivery_form)
  end

  def create
    return unless @sale = find_and_check(:sales, params[:sale_id]||params[:sale_id]||session[:current_sale_id])
    unless @sale.order?
      notify(:sale_already_invoiced, :warning)
      redirect_to_back
    end
    sale_lines = @sale.lines.find_all_by_reduction_origin_id(nil)
    notify(:no_lines_found, :warning) if sale_lines.empty?

    @outgoing_delivery_lines = sale_lines.collect{|x| OutgoingDeliveryLine.new(:sale_line_id=>x.id, :quantity=>x.undelivered_quantity)}
    @outgoing_delivery = OutgoingDelivery.new(:pretax_amount=>@sale.undelivered("pretax_amount"), :amount=>@sale.undelivered("amount"), :planned_on=>Date.today, :transporter_id=>@sale.transporter_id, :contact_id=>@sale.delivery_contact_id||@sale.client.default_contact)
    # session[:current_outgoing_delivery] = @outgoing_delivery.id
  
    if request.post?
      @outgoing_delivery = @sale.deliveries.new(params[:outgoing_delivery])
      
      ActiveRecord::Base.transaction do
        if saved = @outgoing_delivery.save
          for line in sale_lines
            if params[:outgoing_delivery_line][line.id.to_s][:quantity].to_f > 0
              outgoing_delivery_line = @outgoing_delivery.lines.new(:sale_line_id=>line.id, :quantity=>params[:outgoing_delivery_line][line.id.to_s][:quantity].to_f)
              saved = false unless outgoing_delivery_line.save
              @outgoing_delivery.errors.add_from_record(outgoing_delivery_line)
            end
          end
        end
        raise ActiveRecord::Rollback unless saved  
        redirect_to :action=>:sale, :step=>:deliveries, :id=>session[:current_sale_id] 
      end
    end
    render_restfully_form(:id=>@outgoing_delivery_form)
  end

  def destroy
    return unless @outgoing_delivery = find_and_check(:outgoing_delivery)
    if request.post? or request.delete?
      @outgoing_delivery.destroy
    end
    redirect_to_current
  end

  def edit
    return unless @outgoing_delivery = find_and_check(:outgoing_delivery)
    session[:current_outgoing_delivery] = @outgoing_delivery.id
    @sale = @outgoing_delivery.sale
    # return unless @sale = find_and_check(:sales, session[:current_sale_id])
    # sale_lines = SaleLine.find(:all,:conditions=>{:company_id=>@current_company.id, :sale_id=>session[:current_sale_id]})
    # @outgoing_delivery_lines = OutgoingDeliveryLine.find(:all,:conditions=>{:company_id=>@current_company.id, :outgoing_delivery_id=>@outgoing_delivery.id})
    @outgoing_delivery_lines = @outgoing_delivery.lines
    if request.post?
      ActiveRecord::Base.transaction do
        saved = @outgoing_delivery.update_attributes!(params[:outgoing_delivery])
        if saved
          for line in @outgoing_delivery.lines
            saved = false unless line.update_attributes(:quantity=>params[:outgoing_delivery_line][line.sale_line.id.to_s][:quantity])
            @outgoing_delivery.errors.add_from_record(line)
          end
        end
        raise ActiveRecord::Rollback unless saved
        redirect_to :action=>:sale, :step=>:deliveries, :id=>session[:current_sale_id] 
      end
    end
    render_restfully_form(:id=>@outgoing_delivery_form)
  end

  def update
    return unless @outgoing_delivery = find_and_check(:outgoing_delivery)
    session[:current_outgoing_delivery] = @outgoing_delivery.id
    @sale = @outgoing_delivery.sale
    # return unless @sale = find_and_check(:sales, session[:current_sale_id])
    # sale_lines = SaleLine.find(:all,:conditions=>{:company_id=>@current_company.id, :sale_id=>session[:current_sale_id]})
    # @outgoing_delivery_lines = OutgoingDeliveryLine.find(:all,:conditions=>{:company_id=>@current_company.id, :outgoing_delivery_id=>@outgoing_delivery.id})
    @outgoing_delivery_lines = @outgoing_delivery.lines
    if request.post?
      ActiveRecord::Base.transaction do
        saved = @outgoing_delivery.update_attributes!(params[:outgoing_delivery])
        if saved
          for line in @outgoing_delivery.lines
            saved = false unless line.update_attributes(:quantity=>params[:outgoing_delivery_line][line.sale_line.id.to_s][:quantity])
            @outgoing_delivery.errors.add_from_record(line)
          end
        end
        raise ActiveRecord::Rollback unless saved
        redirect_to :action=>:sale, :step=>:deliveries, :id=>session[:current_sale_id] 
      end
    end
    render_restfully_form(:id=>@outgoing_delivery_form)
  end

end
