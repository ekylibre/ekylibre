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

class SaleLinesController < AdminController


  def new
    return unless @sale = find_and_check(:sale, params[:sale_id])
    @sale_line = @sale.lines.new(:price_amount=>0.0, :reduction_percent=>@sale.client.max_reduction_percent)
    unless @sale.draft?
      notify_error(:impossible_to_add_lines)
      redirect_to :controller=>:sales, :action=>:show, :id=>@sale.id, :step=>:products
      return
    end
    session[:current_currency] = @sale.currency
    render_restfully_form
  end

  def create
    return unless @sale = find_and_check(:sale, params[:sale_id])
    @sale_line = @sale.lines.new(:price_amount=>0.0, :reduction_percent=>@sale.client.max_reduction_percent)
    unless @sale.draft?
      notify_error(:impossible_to_add_lines)
      redirect_to :controller=>:sales, :action=>:show, :id=>@sale.id, :step=>:products
      return
    end
    @sale_line.attributes = params[:sale_line]
    ActiveRecord::Base.transaction do
      if saved = @sale_line.save
        if @sale_line.subscription?
          @subscription = @sale_line.new_subscription(params[:subscription])
          saved = false unless @subscription.save
          @subscription.errors.add_from_record(@sale_line)
        end
        raise ActiveRecord::Rollback unless saved
      end
      return if save_and_redirect(@sale_line, :url=>{:controller=>:sales, :action=>:show, :id=>@sale.id}, :saved=>saved) 
    end
    render_restfully_form
  end

  def destroy
    return unless @sale_line = find_and_check(:sale_line)
    @sale_line.destroy
    redirect_to_current
  end

  def detail
    if request.xhr?
      return unless price = find_and_check(:price, params[:price_id])
      @sale = Sale.find_by_id(params[:sale_id]) if params[:sale_id]
      @sale_line = SaleLine.new(:product=>price.product, :price=>price, :price_amount=>0.0, :quantity=>1.0, :unit_id=>price.product.unit_id)
      if @sale
        @sale_line.sale = @sale
        @sale_line.reduction_percent = @sale.client.max_reduction_percent 
      end
      render :partial=>"sale_lines/detail#{'_row' if params[:mode]=='row'}_form"
    else
      redirect_to sales_url
    end
  end

  def edit
    return unless @sale_line = find_and_check(:sale_line)
    @sale = @sale_line.sale 
    t3e :product=>@sale_line.product.name
    render_restfully_form
  end

  def update
    return unless @sale_line = find_and_check(:sale_line)
    @sale = @sale_line.sale 
    @sale_line.attributes = params[:sale_line]
    return if save_and_redirect(@sale_line)
    t3e :product=>@sale_line.product.name
    render_restfully_form
  end

end
