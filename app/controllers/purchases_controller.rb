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

class PurchasesController < ApplicationController
  manage_restfully :supplier_id=>"@current_company.entities.find(params[:supplier_id]).id rescue nil", :planned_on=>"Date.today+2", :redirect_to=>'{:action=>:show, :step=>:products, :id=>"id"}'

  list(:deliveries, :model=>:incoming_deliveries, :children=>:lines, :conditions=>{:company_id=>['@current_company.id'], :purchase_id=>['session[:current_purchase_id]']}) do |t|
    t.column :address, :through=>:contact, :children=>:product_name
    t.column :planned_on, :children=>false
    t.column :moved_on, :children=>false
    t.column :quantity, :datatype=>:decimal
    t.column :pretax_amount
    t.column :amount
    t.action :edit, :if=>'RECORD.purchase.order? '
    t.action :destroy, :if=>'RECORD.purchase.order? ', :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  list(:payment_uses, :model=>:outgoing_payment_uses, :conditions=>["#{OutgoingPaymentUse.table_name}.company_id=? AND #{OutgoingPaymentUse.table_name}.expense_id=? ", ['@current_company.id'], ['session[:current_purchase_id]']]) do |t|
    t.column :number, :through=>:payment, :url=>true
    t.column :amount, :through=>:payment, :label=>"payment_amount", :url=>true
    t.column :amount
    t.column :name, :through=>[:payment, :mode]
    t.column :downpayment
    t.column :to_bank_on, :through=>:payment, :label=>:column
    t.action :destroy, :controller=>:finances, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete#, :if=>'RECORD.expense.shipped == false'
  end

  list(:undelivered_lines, :model=>:purchase_lines, :conditions=>{:company_id=>['@current_company.id'], :purchase_id=>['session[:current_purchase_id]']}) do |t|
    t.column :name, :through=>:product
    t.column :pretax_amount, :through=>:price
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :pretax_amount
    t.column :amount
    t.column :undelivered_quantity, :datatype=>:decimal
  end

  list(:lines, :model=>:purchase_lines, :conditions=>{:company_id=>['@current_company.id'], :purchase_id=>['session[:current_purchase_id]']}) do |t|
    t.column :name, :through=>:product, :url=>true
    t.column :annotation
    t.column :tracking_serial
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :pretax_amount, :through=>:price
    t.column :pretax_amount
    t.column :amount
    t.action :edit, :if=>'RECORD.purchase.draft? '
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>'RECORD.purchase.draft? '
  end



  list(:conditions=>search_conditions(:purchase, :purchases=>[:created_on, :pretax_amount, :amount, :number, :reference_number, :comment], :entities=>[:code, :full_name]), :joins=>:supplier, :line_class=>'RECORD.state', :order=>"created_on DESC, number DESC") do |t|
    t.column :number, :url=>{:action=>:show, :step=>:default}
    t.column :reference_number, :url=>{:action=>:show, :step=>:products}
    t.column :created_on
    # t.column :planned_on
    # t.column :moved_on
    t.column :full_name, :through=>:supplier, :url=>true
    # t.column :code, :through=>:supplier, :url=>{:controller=>:relations, :action=>:entity}, :label=>"supplier_code"
    t.column :comment
    # t.column :shipped
    t.column :state_label
    t.column :paid_amount
    t.column :amount
    t.action :show, :url=>{:format=>:pdf}, :image=>:print
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end

  # Displays details of one purchase selected with +params[:id]+
  def show
    return unless @purchase = find_and_check(:purchase)
    respond_to do |format|
      format.html do
        session[:current_purchase_id] = @purchase.id
        if params[:step] and not ["products", "deliveries", "summary"].include?(params[:step])
          state  = @purchase.state
          redirect_to :action=>:show, :id=>@purchase.id,  :step=>(["invoiced", "finished"].include?(state) ? :summary : state=="processing" ? :deliveries : :products)
          return
        end
        if params[:step] == "deliveries"
          if @purchase.deliveries.size <= 0 and @purchase.order? and @purchase.has_content?
            redirect_to :action=>:new, :controller=>:incoming_deliveries, :purchase_id=>@purchase.id
          elsif @purchase.deliveries.size <= 0 and @purchase.invoice?
            notify(:purchase_already_invoiced)
          elsif @purchase.lines.size <= 0
            notify_warning(:no_lines_found)
            redirect_to :action=>:show, :step=>:products, :id=>@purchase.id
          end
        end
        t3e @purchase.attributes, :supplier=>@purchase.supplier.full_name, :state=>@purchase.state_label
      end
      format.pdf { render_print_purchase(@purchase) }
    end
  end

  def abort
    return unless @purchase = find_and_check(:purchase)
    if request.post?
      @purchase.abort
    end
    redirect_to :action=>:show, :id=>@purchase.id
  end

  def confirm
    return unless @purchase = find_and_check(:purchase)
    step = :products
    if request.post?
      step = :deliveries if @purchase.confirm
    end
    redirect_to :action=>:show, :step=>step, :id=>@purchase.id
  end

  def correct
    return unless @purchase = find_and_check(:purchase)
    if request.post?
      @purchase.correct
    end
    redirect_to :action=>:show, :step=>:products, :id=>@purchase.id
  end

  def finish
    return unless @purchase = find_and_check(:purchase)
    if request.post?
      @purchase.finish
    end
    redirect_to :action=>:show, :step=>:summary, :id=>@purchase.id
  end

  def invoice
    return unless @purchase = find_and_check(:purchase)
    if request.post?
      ActiveRecord::Base.transaction do
        raise ActiveRecord::Rollback unless @purchase.invoice
        redirect_to :action=>:show, :step=>:summary, :id=>@purchase.id
        return
      end
    end
    redirect_to :action=>:show, :step=>:products, :id=>@purchase.id
  end

  def propose
    return unless @purchase = find_and_check(:purchase)
    if request.post?
      @purchase.propose
    end
    redirect_to :action=>:show, :step=>:products, :id=>@purchase.id
  end

  def refuse
    return unless @purchase = find_and_check(:purchase)
    if request.post?
      @purchase.refuse
    end
    redirect_to :action=>:show, :step=>:products, :id=>@purchase.id
  end

  # Displays the main page with the list of purchases
  def index
    session[:purchase_key] = params[:key] = params[:key] || session[:purchase_key] || ""
  end

end
