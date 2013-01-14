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

class ProductGroupEventsController < AdminController
  manage_restfully

  respond_to :pdf, :html, :xml

  unroll_all

  list do |t|
    t.column :name, :through=>:product_group, :url=>true
    t.column :name, :through=>:nature, :url=>true
    t.column :name, :through=>:watcher, :url=>true
    t.column :comment
    t.action :show, :url=>{:format=>:pdf}, :image=>:print
    t.action :edit
    t.action :destroy, :if=>"RECORD.destroyable\?"
  end

  # Show a list of @animal_event
  # @TODO FIX Jasperreport gem calling method to work with format pdf
  def index
    @product_group_event = ProductGroupEvent.all
    respond_to do |format|
     format.json { render json: @product_group_event }
     format.xml { render xml: @product_group_event , :include => :product_group}
     format.pdf { respond_with @product_group_event }
     format.html
     end
  end

  # Show one @animal_event with params_id
  def show
    return unless @product_group_event = find_and_check
    session[:current_product_group_event_id] = @product_group_event.id
    t3e @product_group_event
  end

end
