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

class TrackingsController < AdminController
  unroll_all

  list(:operation_lines, :conditions=>{:tracking_id=>['session[:current_tracking_id]']}, :order=>'operation_id') do |t|
    t.column :name, :through=>:operation, :url=>true
    t.column :direction
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :name, :through=>:warehouse, :url=>true
  end

  list(:purchase_lines, :conditions=>{:tracking_id=>['session[:current_tracking_id]']}, :order=>'purchase_id') do |t|
    t.column :number, :through=>:purchase, :url=>true
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :name, :through=>:warehouse, :url=>true
  end

  list(:sale_lines, :conditions=>{:tracking_id=>['session[:current_tracking_id]']}, :order=>'sale_id') do |t|
    t.column :number, :through=>:sale, :url=>true
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :name, :through=>:warehouse, :url=>true
  end

  list(:stocks, :conditions=>{:tracking_id=>['session[:current_tracking_id]']}, :line_class=>'RECORD.state') do |t|
    t.column :weight, :through=>:product, :label=>:column
    t.column :quantity_max
    t.column :quantity_min
    t.column :critic_quantity_min
    t.column :virtual_quantity
    t.column :quantity
    t.column :label, :through=>:unit
    t.column :name, :through=>:warehouse, :url=>true
  end

  # Displays details of one tracking selected with +params[:id]+
  def show
    return unless @tracking = find_and_check(:trackings)
    session[:current_tracking_id] = @tracking.id
    t3e @tracking.attributes
  end

end
