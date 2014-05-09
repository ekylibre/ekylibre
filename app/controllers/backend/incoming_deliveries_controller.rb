# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2009-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
  manage_restfully

  unroll

  respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

  list do |t|
    t.column :number, url: true
    t.column :sender, url: true
    t.column :reference_number, url: true
    t.column :received_at
    t.column :mode
    t.column :purchase, url: true
    # t.action :confirm, method: :post, if: :confirmable?, confirm: true
    t.action :new,     on: :none
    t.action :invoice, on: :both, method: :post
    t.action :edit
    t.action :destroy
  end

  # Liste des items d'une appro
  list(:items, model: :incoming_delivery_items, conditions: {delivery_id: 'params[:id]'.c}, order: {created_at: :desc}) do |t|
    t.column :product, url: true
    t.column :population
    t.column :unit, through: :variant, label_method: :unit_name
    t.column :variant, url: true
    t.column :container, url: true
    t.column :amount, through: :purchase_item, hidden: true, currency: true, url: true
    t.column :created_at, hidden: true
  end

  def confirm
    return unless incoming_delivery = find_and_check
    incoming_delivery.execute if request.post?
    redirect_to action: :index, mode: :unconfirmed
  end

  def invoice
    purchase = IncomingDelivery.invoice(params[:id].split(','))
    redirect_to backend_purchase_url(purchase)
  end

end
