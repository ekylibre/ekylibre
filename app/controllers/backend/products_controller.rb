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

class Backend::ProductsController < BackendController
  manage_restfully :t3e => {:nature_name => :nature_name}

  respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

  unroll

  # def unroll
  #   conditions = []
  #   keys = params[:q].to_s.strip.mb_chars.downcase.normalize.split(/[\\s\\,]+/)
  #   if params[:id]
  #     conditions = {:id => params[:id]}
  #     searchable_columns = columns.delete_if{ |c| c[:column].type == :boolean }
  #   elsif keys.size > 0
  #     conditions[0] = '('
  #     keys.each_with_index do |key, index|
  #       conditions[0] << ') AND (' if index > 0
  #       conditions[0] << [:name, :description].collect{|column| "LOWER(CAST(#{column} AS VARCHAR)) LIKE ?"}.join(' OR ')
  #       conditions += [ "%" + key + "%" ]*2
  #     end
  #     conditions[0] << ')'
  #   end
  #   items = Product.where(conditions)
  #   unless params[:variety].blank?
  #     items = items.where(:variety => params[:variety])
  #   end
  #   unless params[:abilities].blank?
  #     items = items.where("nature_id IN (SELECT product_nature_id FROM product_nature_abilities WHERE nature IN (?))", params[:abilities].strip.split(/[\s\,]+/))
  #   end

  #   respond_to do |format|
  #     format.html { render :file => "tmp/cache/unroll/backend/products/__default__.html.haml", :locals => { :items => items, :keys => keys, :search => params[:q].to_s.capitalize.strip }, :layout => false }
  #     format.json { render :json => items.collect{|item| {:label => item.label, :id => item.id}}.to_json }
  #     format.xml  { render  :xml => items.collect{|item| {:label => item.label, :id => item.id}}.to_xml }
  #   end
  # end

  list do |t|
    t.column :active
    t.column :number, url: true
    t.column :name, url: true
    t.column :variant
    t.column :variety
    t.column :description
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  def index
    @product = Product.all
    respond_with @product, :include => [:father, :mother]
  end

  # content product list of the consider product
  list(:contained_products, :model => :product_localizations, :conditions => {container_id: 'params[:id]'.c}, :order => "started_at DESC") do |t|
    t.column :product, url: true
    t.column :nature
    t.column :started_at
    t.column :arrival_cause
    t.column :stopped_at
    t.column :departure_cause
  end

  # localization of the consider product
  list(:places, :model => :product_localizations, :conditions => {product_id: 'params[:id]'.c}, :order => "started_at DESC") do |t|
    t.column :container, url: true
    t.column :nature
    t.column :started_at
    t.column :arrival_cause
    t.column :stopped_at
    t.column :departure_cause
  end

  # groups of the consider product
  list(:groups, :model => :product_memberships, :conditions => {member_id: 'params[:id]'.c}, :order => "started_at DESC") do |t|
    t.column :group, url: true
    t.column :started_at
    t.column :stopped_at
  end

  # members of the consider product
  list(:members, :model => :product_memberships, :conditions => {group_id: 'params[:id]'.c}, :order => "started_at ASC") do |t|
    t.column :member, url: true
    t.column :started_at
    t.column :stopped_at
  end

  # indicators of the consider product
  list(:indicators, :model => :product_indicator_data, :conditions => {product_id: 'params[:id]'.c}, :order => "created_at DESC") do |t|
    t.column :indicator
    t.column :measured_at
    t.column :value
  end

  # incidents of the consider product
  list(:incidents, :conditions => {target_id: 'params[:id]'.c}, :order => "observed_at DESC") do |t|
    t.column :name, url: true
    t.column :nature
    t.column :observed_at
    t.column :gravity
    t.column :priority
    t.column :state
  end

  # incidents of the consider product
  list(:intervention_casts, :conditions => {actor_id: 'params[:id]'.c}) do |t|
    t.column :intervention, url: true
    t.column :roles
    t.column :variable
    t.column :started_at, through: :intervention
    t.column :stopped_at, through: :intervention
  end


  def show
    return unless @product = find_and_check
    if @product.type != "Product"
      redirect_to controller: @product.type.tableize, action: :show, id: @product.id
      return
    end
    t3e @product, :nature_name => @product.nature_name
    respond_with(@product, :include => [:father, :mother, :nature, {:memberships => {:include => :group},:indicator_data => {:include => :indicator}, :product_localizations => {:include => :container}}])
  end

end
