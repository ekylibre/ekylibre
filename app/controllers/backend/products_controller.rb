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

  list do |t|
    t.column :active
    t.column :number, :url => true
    t.column :name, :url => true
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
