# -*- coding: utf-8 -*-
# == License
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::SaleItemsController < BackendController
  manage_restfully only: [:edit, :update, :destroy], t3e: {product: :variant_name}

  def show
    if @sale_item = SaleItem.find_by(id: params[:id])
      redirect_to controller: :sales, id: @sale_item.sale_id
    else
      redirect_to backend_sales_url
    end
  end

  alias :index :show

  def new
    return unless @sale = find_and_check(:sale, params[:sale_id])
    unless @sale.draft?
      notify_error(:impossible_to_add_items)
      redirect_to controller: :sales, action: :show, id: @sale.id
      return
    end
    @sale_item = @sale.items.new(unit_price_amount: 0.0, reduction_percentage: @sale.client.maximal_reduction_percentage)
  end

  def create
    return unless @sale = find_and_check(:sale, params[:sale_id])
    unless @sale.draft?
      notify_error(:impossible_to_add_items)
      redirect_to controller: :sales, action: :show, id: @sale.id
      return
    end
    @sale_item = @sale.items.new(unit_price_amount: 0.0, reduction_percentage: @sale.client.maximal_reduction_percentage)
    @sale_item.attributes = permitted_params
    ActiveRecord::Base.transaction do
      if saved = @sale_item.save
        if @sale_item.subscribing?
          @subscription = @sale_item.new_subscription(params[:subscription])
          saved = false unless @subscription.save
          @subscription.errors.add_from_record(@sale_item)
        end
        raise ActiveRecord::Rollback unless saved
      end
      return if save_and_redirect(@sale_item, url: {controller: :sales, action: :show, id: @sale.id}, :saved => saved)
    end
  end

  # def detail
  #   if request.xhr?
  #     return unless price = find_and_check(:product_price_template, params[:price_id])
  #     @sale = Sale.find_by_id(params[:sale_id]) if params[:sale_id]
  #     @sale_item = SaleItem.new(:product => price.product, :price => price, :unit_price_amount => 0.0, :quantity => 1.0)
  #     if @sale
  #       @sale_item.sale = @sale
  #       @sale_item.reduction_percentage = @sale.client.maximal_reduction_percentage
  #     end
  #     render partial: "backend/sale_items/detail#{'_row' if params[:mode]=='row'}_form"
  #   else
  #     redirect_to sales_url
  #   end
  # end

end
