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

class Backend::PurchasesController < BackendController
  manage_restfully :planned_on => "Date.today+2", :redirect_to => '{:action => :show, :step => :products, :id => "id"}'

  unroll_all

  list(:conditions => search_conditions(:purchase, :purchases => [:created_on, :pretax_amount, :amount, :number, :reference_number, :description], :entities => [:code, :full_name]), :joins => :supplier, :line_class => 'RECORD.state', :order => "created_on DESC, number DESC") do |t|
    t.column :number, :url => {:action => :show, :step => :default}
    t.column :reference_number, :url => {:action => :show, :step => :products}
    t.column :created_on
    # t.column :planned_on
    # t.column :moved_on
    t.column :full_name, :through => :supplier, :url => true
    t.column :description
    # t.column :shipped
    t.column :state_label
    # t.column :paid_amount, :currency => true
    t.column :amount, :currency => true
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    t.action :destroy, :if => "RECORD.destroyable\?"
  end

  # Displays the main page with the list of purchases
  def index
    session[:purchase_key] = params[:q]
  end


  list(:deliveries, :model => :incoming_deliveries, :children => :items, :conditions => {:purchase_id => ['session[:current_purchase_id]']}) do |t|
    t.column :coordinate, :through => :address, :children => :product_name
    t.column :planned_on, :children => false
    t.column :moved_on, :children => false
    t.column :quantity, :datatype => :decimal
    t.column :pretax_amount, :currency => {:body => "RECORD.purchase.currency", :children => "RECORD.delivery.purchase.currency"}
    t.column :amount, :currency => {:body => "RECORD.purchase.currency", :children => "RECORD.delivery.purchase.currency"}
    t.action :edit, :if => :order?
    t.action :destroy, :if => :order?
  end

  # list(:payment_uses, :model => :outgoing_payment_uses, :conditions => ["#{OutgoingPaymentUse.table_name}.expense_id=? ", ['session[:current_purchase_id]']]) do |t|
  #   t.column :number, :through => :payment, :url => true
  #   t.column :amount, :currency => "RECORD.payment.currency", :through => :payment, :label => "payment_amount", :url => true
  #   t.column :amount, :currency => "RECORD.payment.currency"
  #   t.column :name, :through => [:payment, :mode]
  #   t.column :downpayment
  #   t.column :to_bank_on, :through => :payment, :label => :column, :datatype => :date
  #   t.action :destroy#, :if => 'RECORD.expense.shipped == false'
  # end

  list(:undelivered_items, :model => :purchase_items, :conditions => {:purchase_id => ['session[:current_purchase_id]']}) do |t|
    t.column :name, :through => :product
    t.column :pretax_amount, :currency => true, :through => :price
    t.column :quantity
    t.column :unit
    t.column :pretax_amount, :currency => true
    t.column :amount, :currency => true
    t.column :undelivered_quantity, :datatype => :decimal
  end

  list(:items, :model => :purchase_items, :conditions => {:purchase_id => ['session[:current_purchase_id]']}) do |t|
    t.column :name, :through => :product, :url => true
    t.column :annotation
    t.column :tracking_serial
    t.column :quantity
    t.column :unit
    t.column :pretax_amount, :currency => true, :through => :price
    t.column :pretax_amount, :currency => true
    t.column :amount, :currency => true
    t.action :edit, :if => :draft?
    t.action :destroy, :if => :draft?
  end



  # Displays details of one purchase selected with +params[:id]+
  def show
    return unless @purchase = find_and_check
    respond_to do |format|
      format.html do
        session[:current_purchase_id] = @purchase.id
        if params[:step] and not ["products", "deliveries", "summary"].include?(params[:step])
          state  = @purchase.state
          params[:step] = (@purchase.invoice? ? :summary : @purchase.order? ? :deliveries : :products).to_s
          # redirect_to :action => :show, :id => @purchase.id,  :step => (["invoiced", "finished"].include?(state) ? :summary : state=="processing" ? :deliveries : :products)
          # return
        end
        if params[:step] == "deliveries"
          if @purchase.deliveries.size <= 0 and @purchase.order? and @purchase.has_content?
            redirect_to :action => :new, :controller => :incoming_deliveries, :purchase_id => @purchase.id
          elsif @purchase.deliveries.size <= 0 and @purchase.invoice?
            notify(:purchase_already_invoiced)
          elsif @purchase.items.size <= 0
            notify_warning(:no_items_found)
            redirect_to :action => :show, :step => :products, :id => @purchase.id
          end
        end
        t3e @purchase.attributes, :supplier => @purchase.supplier.full_name, :state => @purchase.state_label
      end
      format.xml { render :xml  =>  @purchase.to_xml }
      format.pdf { render_print_purchase(@purchase) }
    end
  end

  def abort
    return unless @purchase = find_and_check(:purchase)
    if request.post?
      @purchase.abort
    end
    redirect_to :action => :show, :id => @purchase.id
  end

  def confirm
    return unless @purchase = find_and_check(:purchase)
    step = :products
    if request.post?
      step = :deliveries if @purchase.confirm
    end
    redirect_to :action => :show, :step => step, :id => @purchase.id
  end

  def correct
    return unless @purchase = find_and_check(:purchase)
    if request.post?
      @purchase.correct
    end
    redirect_to :action => :show, :step => :products, :id => @purchase.id
  end

  def invoice
    return unless @purchase = find_and_check(:purchase)
    ActiveRecord::Base.transaction do
      raise ActiveRecord::Rollback unless @purchase.invoice(params[:invoiced_on])
      redirect_to :action => :show, :step => :summary, :id => @purchase.id
      return
    end
    redirect_to :action => :show, :step => :products, :id => @purchase.id
  end

  def propose
    return unless @purchase = find_and_check(:purchase)
    if request.post?
      @purchase.propose
    end
    redirect_to :action => :show, :step => :products, :id => @purchase.id
  end

  def refuse
    return unless @purchase = find_and_check(:purchase)
    if request.post?
      @purchase.refuse
    end
    redirect_to :action => :show, :step => :products, :id => @purchase.id
  end

end
