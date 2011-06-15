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

class ProductComponentsController < ApplicationController

  def new
    return unless @product = find_and_check(:products, params[:product_id]||session[:product_id])
    if request.post?
      @product_component = ProductComponent.new(params[:product_component])
      @product_component.company_id = @current_company.id
      @product_component.product_id = @product.id
      return if save_and_redirect(@product_component, :url=>{:action=>:product, :id=>@product_component.product_id})
    else
      @product_component = ProductComponent.new(:quantity=>1.0)
    end
    t3e :product=>@product.name
    render_restfully_form
  end

  def create
    return unless @product = find_and_check(:products, params[:product_id]||session[:product_id])
    if request.post?
      @product_component = ProductComponent.new(params[:product_component])
      @product_component.company_id = @current_company.id
      @product_component.product_id = @product.id
      return if save_and_redirect(@product_component, :url=>{:action=>:product, :id=>@product_component.product_id})
    else
      @product_component = ProductComponent.new(:quantity=>1.0)
    end
    t3e :product=>@product.name
    render_restfully_form
  end

  def destroy
    return unless @product_component = find_and_check(:product_component)
    if request.post? or request.delete?
      @product_component.update_attributes!(:active=>false)
    end
    redirect_to :controller=>:products, :id=>session[:product_id]
  end

  def edit
    return unless @product_component = find_and_check(:product_component)
    @product = @product_component.product
    if request.post?
      @product_component.attributes = params[:product_component]
      return if save_and_redirect(@product_component, :url=>{:action=>:product, :id=>@product_component.product_id})
    end
    t3e :product=>@product.name, :component=>@product_component.name
    render_restfully_form
  end

  def update
    return unless @product_component = find_and_check(:product_component)
    @product = @product_component.product
    if request.post?
      @product_component.attributes = params[:product_component]
      return if save_and_redirect(@product_component, :url=>{:action=>:product, :id=>@product_component.product_id})
    end
    t3e :product=>@product.name, :component=>@product_component.name
    render_restfully_form
  end

end
