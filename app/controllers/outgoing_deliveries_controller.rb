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

  list(:conditions=>light_search_conditions(:outgoing_deliveries=>[:number, :reference_number, :weight, :amount, :pretax_amount], :entities=>[:full_name, :code])+moved_conditions(OutgoingDelivery)) do |t|
    t.column :number, :url=>true
    t.column :number, :through=>:transport, :url=>true
    t.column :full_name, :through=>:transporter, :url=>true
    t.column :reference_number
    t.column :comment
    t.column :planned_on
    t.column :moved_on
    t.column :name, :through=>:mode
    # t.column :number, :through=>:sale, :url=>true
    t.column :weight
    t.column :amount
    t.action :edit
    t.action :destroy
  end

  # Displays the main page with the list of outgoing deliveries
  def index
  end

  list(:lines, :model=>:outgoing_delivery_lines, :conditions=>{:company_id=>['@current_company.id'], :delivery_id=>['session[:current_outgoing_delivery_id]']}) do |t|
    t.column :name, :through=>:product, :url=>true
    t.column :number, :through=>:tracking, :url=>true
    t.column :quantity
    t.column :name, :through=>:unit
    t.column :pretax_amount
    t.column :amount
    t.column :name, :through=>:warehouse, :url=>true
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
    sale_lines = sale.lines.find_all_by_reduction_origin_id(nil)
    notify_warning(:no_lines_found) if sale_lines.empty?

    @outgoing_delivery_lines = sale_lines.collect{|x| OutgoingDeliveryLine.new(:sale_line_id=>x.id, :quantity=>x.undelivered_quantity)}
    @outgoing_delivery = OutgoingDelivery.new(:sale_id=>sale.id, :pretax_amount=>sale.undelivered("pretax_amount"), :amount=>sale.undelivered("amount"), :planned_on=>Date.today, :transporter_id=>sale.transporter_id, :contact_id=>sale.delivery_contact_id||sale.client.default_contact)
    render_restfully_form
  end

  def create
    return unless sale = find_and_check(:sales, params[:sale_id]||params[:sale_id]||session[:current_sale_id])
    unless sale.deliverable?
      notify_warning(:sale_already_invoiced)
      redirect_to_back
      return
    end
    sale_lines = sale.lines.find_all_by_reduction_origin_id(nil)
    notify_warning(:no_lines_found) if sale_lines.empty?
    @outgoing_delivery_lines = []
    @outgoing_delivery = sale.deliveries.new(params[:outgoing_delivery])      
    ActiveRecord::Base.transaction do
      if saved = @outgoing_delivery.save
        puts [saved, @outgoing_delivery.errors].inspect

        for line in sale_lines
          quantity = params[:outgoing_delivery_line][line.id.to_s][:quantity].to_f rescue 0
          outgoing_delivery_line = @outgoing_delivery.lines.new(:sale_line_id=>line.id, :quantity=>quantity)
          if quantity > 0
            saved = false unless outgoing_delivery_line.save
            puts [saved, outgoing_delivery_line, outgoing_delivery_line.errors.to_hash].inspect
            @outgoing_delivery.errors.add_from_record(outgoing_delivery_line)
          end
          @outgoing_delivery_lines << outgoing_delivery_line
        end if params[:outgoing_delivery_line].is_a? Hash
      end
      if saved
        redirect_to_back
        return
      end
      raise ActiveRecord::Rollback unless saved  
    end
    render_restfully_form
  end

  def edit
    return unless @outgoing_delivery = find_and_check(:outgoing_delivery)
    session[:current_outgoing_delivery] = @outgoing_delivery.id
    @outgoing_delivery_lines = @outgoing_delivery.lines
    t3e @outgoing_delivery.attributes
    render_restfully_form
  end

  def update
    return unless @outgoing_delivery = find_and_check(:outgoing_delivery)
    session[:current_outgoing_delivery] = @outgoing_delivery.id
    @outgoing_delivery_lines = @outgoing_delivery.lines
    ActiveRecord::Base.transaction do
      saved = @outgoing_delivery.update_attributes!(params[:outgoing_delivery])
      if saved
        for line in @outgoing_delivery.lines
          saved = false unless line.update_attributes(:quantity=>params[:outgoing_delivery_line][line.sale_line.id.to_s][:quantity])
          @outgoing_delivery.errors.add_from_record(line)
        end
      end
      if saved
        redirect_to_back
        return
      end
      raise ActiveRecord::Rollback unless saved
    end
    t3e @outgoing_delivery.attributes
    render_restfully_form
  end

  def destroy
    return unless @outgoing_delivery = find_and_check(:outgoing_delivery)
    @outgoing_delivery.destroy
    redirect_to_current
  end

end
