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

class Backend::ProductVarietiesController < BackendController
  manage_restfully

  unroll_all

  list do |t|
    t.column :name, :url => true
    t.column :name, :through=>:parent, :url=>true
    t.column :comment
    t.column :code
    t.column :description
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  # Show a list of animals natures
  def index
  end

  # Show one Product with params_id
  def show
    return unless @product_variety = find_and_check
    session[:current_product_variety_id] = @product_variety.id
    t3e @product_variety
  end

end
