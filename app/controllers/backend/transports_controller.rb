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

class Backend::TransportsController < BackendController
  unroll

  list(:children => :deliveries, :conditions => light_search_conditions(:transports => [:number, :description], :entities => [:code, :full_name])) do |t|
    t.column :number, :url => true
    t.column :description
    #t.column :created_on, :children => :planned_on
    #t.column :transport_on, :children => :moved_on
    t.column :full_name, :through => :transporter, :children => :default_mail_coordinate, :url => true
    t.column :weight
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    t.action :destroy
  end

  # Displays the main page with the list of transports
  def index
  end


  list(:deliveries, :model => :outgoing_deliveries, :children => :items, :conditions => {:transport_id => ['session[:current_transport_id]']}) do |t|
    t.column :coordinate, :through => :address, :children => :product_name
    t.column :planned_at, :children => false
    #t.column :moved_on, :children => false
    t.column :number, :url => true, :children => false
    # t.column :number, :through => :sale, :url => true, :children => false
    #t.column :quantity
    #t.column :pretax_amount
    #t.column :amount
    t.column :weight, :children => false
  end

  # Displays details of one transport selected with +params[:id]+
  def show
    return unless @transport = find_and_check(:transports)
    respond_to do |format|
      format.html do
        session[:current_transport_id] = @transport.id
        t3e @transport.attributes
      end
      format.pdf { render_print_transport(@transport) }
    end
  end

  def self.transportable_deliveries_conditions()
    code  = ""
    code += "c = [\"1=1\"]\n"
    code += "if session[:current_transport_id].to_i > 0\n"
    code += "  c[0] += ' AND (transport_id = ? OR (transport_id IS NULL'\n"
    code += "  c << session[:current_transport_id].to_i\n"
    code += "  if session[:current_transporter_id].to_i > 0\n"
    code += "    c[0] += ' AND (transporter_id = ? OR transporter_id IS NULL)'\n"
    code += "    c << session[:current_transporter_id].to_i\n"
    code += "  end\n"
    code += "  c[0] += '))'\n"
    code += "elsif not session[:current_transporter_id].to_i.zero?\n"
    code += "  c[0] += ' AND (transporter_id = ? OR transporter_id IS NULL)'\n"
    code += "  c << session[:current_transporter_id].to_i\n"
    code += "else\n"
    code += "  c[0] += ' AND transporter_id IS NULL'\n"
    code += "end\n"

    code += "c\n"
    return code
  end

  list(:transportable_deliveries, :model => :outgoing_deliveries, :children => :items, :conditions => transportable_deliveries_conditions, :pagination => :none, :order => :planned_at, :line_class => "(RECORD.planned_at<Date.today ? 'critic' : RECORD.planned_at.to_date == Date.today ? 'warning' : '')") do |t|
    t.check_box :selected, :value => '(session[:current_transport_id].to_i.zero? ? RECORD.planned_at <= Date.today : RECORD.transport_id == session[:current_transport_id])'
    t.column :coordinate, :through => :address, :children => :product_name
    t.column :planned_at, :children => false
    #t.column :moved_on, :children => false
    t.column :number, :url => true, :children => false
    # t.column :number, :through => :sale, :url => true, :children => false
    t.column :last_name, :through => :transporter, :children => false, :url => true
    #t.column :quantity
    #t.column :pretax_amount
    #t.column :amount
    t.column :weight, :children => false
  end

  def new
    @transport = Transport.new(:transport_on => Date.today, :responsible_id => @current_user.id, :transporter_id => params[:transporter_id], :responsible_id => @current_user.id)
    session[:current_transport_id] = @transport.id
    session[:current_transporter_id] = @transport.transporter_id
    if request.xhr?
      if params[:transport_id] and transport = Transport.find_by_id(params[:transport_id])
        session[:current_transport_id] ||= transport.id
      end
      render :partial => "deliveries_form"
    else
      # render_restfully_form
    end
  end

  def create
    @transport = Transport.new(params[:transport])
    session[:current_transport_id] = @transport.id
    session[:current_transporter_id] = @transport.transporter_id
    return if save_and_redirect(@transport, :url => {:action => :show, :id => 'id'}) do |transport|
      transport.deliveries.clear
      params[:transportable_deliveries] ||= {}
      for delivery_id, delivery_attrs in params[:transportable_deliveries].select{|k,v| v["selected"].to_i == 1}
        delivery = OutgoingDelivery.find_by_id(delivery_id)
        if delivery and not transport.deliveries.include? delivery
          transport.deliveries << delivery
        end
      end
    end
    # render_restfully_form
  end

  def edit
    return unless @transport = find_and_check(:transports)
    session[:current_transport_id] = @transport.id
    session[:current_transporter_id] = @transport.transporter_id
    t3e @transport.attributes
    # render_restfully_form
  end

  def update
    return unless @transport = find_and_check(:transports)
    session[:current_transport_id] = @transport.id
    session[:current_transporter_id] = @transport.transporter_id
    return if save_and_redirect(@transport, :attributes => params[:transport], :url => {:action => :show, :id => 'id'}) do |transport|
      transport.deliveries.clear
      params[:transportable_deliveries] ||= {}
      for delivery_id, delivery_attrs in params[:transportable_deliveries].select{|k,v| v["selected"].to_i == 1}
        delivery = OutgoingDelivery.find_by_id(delivery_id)
        if delivery and not transport.deliveries.include? delivery
          transport.deliveries << delivery
        end
      end
    end
    t3e @transport.attributes
    # render_restfully_form
  end


  def destroy
    return unless @transport = find_and_check(:transports)
    @transport.destroy if @transport.destroyable?
    redirect_to backend_transports_url
  end

end
