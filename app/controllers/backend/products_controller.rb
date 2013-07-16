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
  manage_restfully

  respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

  unroll_all

  def unroll
    conditions = []
    keys = params[:q].to_s.strip.mb_chars.downcase.normalize.split(/[\\s\\,]+/)
    if params[:id]
      conditions = {:id => params[:id]}
      searchable_columns = columns.delete_if{ |c| c[:column].type == :boolean }
    elsif keys.size > 0
      conditions[0] = '('
      keys.each_with_index do |key, index|
        conditions[0] << ') AND (' if index > 0
        conditions[0] << [:name, :description].collect{|column| "LOWER(CAST(#{column} AS VARCHAR)) LIKE ?"}.join(' OR ')
        conditions += [ "%" + key + "%" ]*2
      end
      conditions[0] << ')'
    end
    items = Product.where(conditions)
    unless params[:variety].blank?
      items = items.where(:variety => params[:variety])
    end
    unless params[:abilities].blank?
      items = items.where("nature_id IN (SELECT product_nature_id FROM product_nature_abilities WHERE nature IN (?))", params[:abilities].strip.split(/[\s\,]+/))
    end

    respond_to do |format|
      format.html { render :file => "tmp/cache/unroll/backend/products/__default__.html.haml", :locals => { :items => items, :keys => keys, :search => params[:q].to_s.capitalize.strip }, :layout => false }
      format.json { render :json => items.collect{|item| {:label => item.label, :id => item.id}}.to_json }
      format.xml  { render  :xml => items.collect{|item| {:label => item.label, :id => item.id}}.to_xml }
    end
  end

  list do |t|
    t.column :active
    t.column :number, :url => true
    t.column :name, :url => true
    t.column :name, :through => :variant
    t.column :variety
    t.column :full_name, :through => :owner
    t.column :description
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  def index
    @product = Product.all
    respond_with @product, :include => [:father, :mother]
  end

  def show
    return unless @product = find_and_check
    session[:current_product_id] = @product.id
    t3e @product
    respond_with(@product, :include => [:father, :mother, :nature, {:memberships => {:include => :group},:indicator_data => {:include => :indicator}, :product_localizations => {:include => :container}}])

  end

end
