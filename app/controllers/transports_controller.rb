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

class TransportsController < ApplicationController

  list(:children=>:deliveries, :conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :created_on, :children=>:planned_on, :url=>true
    t.column :transport_on, :children=>false, :url=>true
    t.column :full_name, :through=>:transporter, :children=>:contact_address, :url=>true
    t.column :weight
    t.action :show, :url=>{:format=>:pdf}, :image=>:print
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  # Displays the main page with the list of transports
  def index
  end


  list(:deliveries, :model=>:outgoing_deliveries, :children=>:lines, :conditions=>{:company_id=>['@current_company.id'], :transport_id=>['session[:current_transport]']}) do |t|
    t.column :address, :through=>:contact, :children=>:product_name
    t.column :planned_on, :children=>false
    t.column :moved_on, :children=>false
    t.column :number, :through=>:sale, :url=>true, :children=>false
    t.column :quantity
    t.column :pretax_amount
    t.column :amount
    t.column :weight, :children=>false
    t.action :delivery_delete, :method=>:delete, :controller=>:transports, :confirm=>:are_you_sure_you_want_to_delete_outgoing_delivery
  end

  # Displays details of one transport selected with +params[:id]+
  def show
    return unless @transport = find_and_check(:transports)
    session[:current_transport] = @transport.id
    t3e @transport.attributes
  end

  def new
    @transport = Transport.new(:transport_on=>Date.today, :responsible_id=>@current_user.id)
    @transport.responsible_id = @current_user.id
    session[:current_transport] = 0
    render_restfully_form
  end

  def create
    session[:current_transport] = 0
    @transport = Transport.new(params[:transport])
    @transport.responsible_id = @current_user.id
    @transport.company_id = @current_company.id
    return if save_and_redirect(@transport, :url=>{:action=>:deliveries, :id=>@transport.id})
    render_restfully_form
  end

  def destroy
    #raise Exception.new params.inspect
    return unless @transport = find_and_check(:transports)
    if request.post? or request.delete?
      @transport.destroy
    end
    redirect_to transports_url
  end

  def deliveries
    return unless @transport = find_and_check(:transports, params[:id]||session[:current_transport])
    session[:current_transport] = @transport.id
    if request.post?
      return unless outgoing_delivery = find_and_check(:outgoing_deliveries, params[:outgoing_delivery][:id].to_i)
      if outgoing_delivery
        redirect_to :action=>:edit, :id=>@transport.id if outgoing_delivery.update_attributes(:transport_id=>@transport.id) 
      end
    end
  end

  def delivery_delete
    return unless @outgoing_delivery =  find_and_check(:outgoing_delivery)
    if request.post? or request.delete?
      @outgoing_delivery.update_attributes!(:transport_id=>nil)
    end
    redirect_to_current
  end

  def edit
    return unless @transport = find_and_check(:transports)
    session[:current_transport] = @transport.id
    if request.post?
      return if save_and_redirect(@transport, :url=>{:action=>:deliveries, :id=>@transport.id}, :attributes=>params[:transport])
    end
  end

  def update
    return unless @transport = find_and_check(:transports)
    session[:current_transport] = @transport.id
    if request.post?
      return if save_and_redirect(@transport, :url=>{:action=>:deliveries, :id=>@transport.id}, :attributes=>params[:transport])
    end
    render :edit
  end

end
