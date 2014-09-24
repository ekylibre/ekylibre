# -*- coding: utf-8 -*-
# == License
# Ekylibre ERP - Simple agricultural ERP
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

class Backend::PurchaseItemsController < BackendController
  manage_restfully only: [:destroy]

  def show
    if @purchase_item = PurchaseItem.find_by(id: params[:id])
      redirect_to controller: :purchases, id: @purchase_item.purchase_id
    else
      redirect_to backend_purchases_url
    end
  end

  alias :index :show


  def new
    return unless @purchase = find_and_check(:purchase, params[:purchase_id])
    unless @purchase.draft?
      notify_warning(:impossible_to_add_items_to_purchase)
      redirect_to action: :show, controller: :purchases, step: :products, id: @purchase.id
      return
    end
    @purchase_item = @purchase.items.new
    t3e @purchase.attributes
  end

  def create
    return unless @purchase = find_and_check(:purchase, params[:purchase_id])
    unless @purchase.draft?
      notify_warning(:impossible_to_add_items_to_purchase)
      redirect_to action: :show, controller: :purchases, step: :products, id: @purchase.id
      return
    end
    return unless product = find_and_check(:product_nature, params[:purchase_item][:product_id].to_i)
    if params[:price]
      price_attrs = params[:price].symbolize_keys.merge(:product_id => product.id, :entity_id => @purchase.supplier_id)
      price = ProductPriceTemplate.find(:first, :conditions => price_attrs)
      price ||= ProductPriceTemplate.create!(price_attrs.merge(:active => true))
      params[:purchase_item][:price_id] = price.id
    end
    @purchase_item = @purchase.items.new(params[:purchase_item])
    return if save_and_redirect(@purchase_item, :url => {controller: :purchases, action: :show, step: :products, id: @purchase.id})
    t3e @purchase.attributes
  end

  def edit
    return unless @purchase_item = find_and_check
    t3e @purchase_item.attributes
  end

  def update
    return unless @purchase_item = find_and_check
    return unless product = find_and_check(:product_natures, params[:purchase_item][:product_id].to_i)
    if params[:price]
      price_attrs = params[:price].symbolize_keys.merge(:product_id => product.id, :entity_id => @purchase_item.purchase.supplier_id)
      price = ProductPriceTemplate.find(:first, :conditions => price_attrs)
      price ||= ProductPriceTemplate.create!(price_attrs.merge(:active => true))
      params[:purchase_item][:price_id] = price.id
    end
    if @purchase_item.update_attributes(params[:purchase_item])
      redirect_to controller: :purchases, action: :show, step: :products, id: @purchase_item.purchase_id
      return
    end
    t3e @purchase_item.attributes
  end

end
