# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
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
  manage_restfully :planned_at => "Date.today+2".c, :redirect_to => '{action: :show, id: "id"}'.c

  unroll

  list(conditions: search_conditions(:purchases => [:created_at, :pretax_amount, :amount, :number, :reference_number, :description], :entities => [:code, :full_name]), joins: :supplier, :line_class => :status, order: {created_at: :desc, number: :desc}) do |t|
    t.column :number, url: {action: :show, step: :default}
    t.column :reference_number, url: {action: :show, step: :products}
    t.column :created_at
    # t.column :planned_at
    # t.column :moved_at
    t.column :supplier, url: true
    t.column :description
    # t.column :shipped
    t.status
    t.column :state_label
    # t.column :paid_amount, currency: true
    t.column :amount, currency: true
    # t.action :show, url: {format: :pdf}, image: :print
    t.action :edit
    t.action :destroy, if: :destroyable?
  end

  list(:items, model: :purchase_items, conditions: {purchase_id: 'params[:id]'.c}) do |t|
    t.column :variant, url: true
    t.column :annotation
    #t.column :tracking_serial
    t.column :quantity
    t.column :unit_price_amount
    t.column :indicator_name
    # t.column :pretax_amount, currency: true, through: :price
    t.column :pretax_amount, currency: true
    t.column :amount, currency: true
    t.action :new, on: :none, url: {purchase_id: 'params[:id]'.c}, if: :draft?
    t.action :edit, if: :draft?
    t.action :destroy, if: :draft?
  end

  list(:deliveries, model: :incoming_deliveries, :children => :items, conditions: {purchase_id: 'params[:id]'.c}) do |t|
    t.column :number, url: true
    t.column :reference_number, url: true
    t.column :address, children: :product_name
    t.column :received_at, children: false
    # t.column :population, :datatype => :decimal
    # t.column :pretax_amount, currency: true
    # t.column :amount, currency: true
    t.action :edit, if: :order?
    t.action :destroy, if: :order?
  end

  # list(:undelivered_items, model: :purchase_items, conditions: {purchase_id: 'params[:id]'.c}) do |t|
  #   t.column :variant
  #   # t.column :pretax_amount, currency: true, through: :price
  #   t.column :quantity
  #   t.column :pretax_amount, currency: true
  #   t.column :amount, currency: true
  #   t.column :undelivered_quantity, :datatype => :decimal
  # end



  # Displays details of one purchase selected with +params[:id]+
  def show
    return unless @purchase = find_and_check
    respond_to do |format|
      format.html do
        # session[:current_purchase_id] = @purchase.id
        if params[:step] and not ["products", "deliveries", "summary"].include?(params[:step])
          state  = @purchase.state
          params[:step] = (@purchase.invoice? ? :summary : @purchase.order? ? :deliveries : :products).to_s
          # redirect_to action: :show, id: @purchase.id,  step: (["invoiced", "finished"].include?(state) ? :summary : state=="processing" ? :deliveries : :products)
          # return
        end
        if params[:step] == "deliveries"
          if @purchase.deliveries.size <= 0 and @purchase.order? and @purchase.has_content?
            redirect_to action: :new, controller: :incoming_deliveries, purchase_id: @purchase.id
          elsif @purchase.deliveries.size <= 0 and @purchase.invoice?
            notify(:purchase_already_invoiced)
          elsif @purchase.items.size <= 0
            notify_warning(:no_items_found)
            redirect_to action: :show, id: @purchase.id
          end
        end
        t3e @purchase.attributes, :supplier => @purchase.supplier.full_name, :state => @purchase.state_label
      end
      format.xml { render :xml => @purchase.to_xml }
      format.pdf { render_print_purchase(@purchase) }
    end
  end

  def abort
    return unless @purchase = find_and_check
    @purchase.abort
    redirect_to action: :show, id: @purchase.id
  end

  def confirm
    return unless @purchase = find_and_check
    @purchase.confirm
    redirect_to action: :show, id: @purchase.id
  end

  def correct
    return unless @purchase = find_and_check
    @purchase.correct
    redirect_to action: :show, id: @purchase.id
  end

  def invoice
    return unless @purchase = find_and_check
    ActiveRecord::Base.transaction do
      raise ActiveRecord::Rollback unless @purchase.invoice(params[:invoiced_at])
    end
    redirect_to action: :show, id: @purchase.id
  end

  def propose
    return unless @purchase = find_and_check
    @purchase.propose
    redirect_to action: :show, id: @purchase.id
  end

  def propose_and_invoice
    return unless @purchase = find_and_check
    ActiveRecord::Base.transaction do
      raise ActiveRecord::Rollback unless @purchase.propose
      raise ActiveRecord::Rollback unless @purchase.confirm
      # raise ActiveRecord::Rollback unless @purchase.deliver
      raise ActiveRecord::Rollback unless @purchase.invoice
    end
    redirect_to action: :show, id: @purchase.id
  end

  def refuse
    return unless @purchase = find_and_check
    @purchase.refuse
    redirect_to action: :show, id: @purchase.id
  end

end
