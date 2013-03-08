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

class Backend::EquipmentsController < BackendController
  manage_restfully

  unroll_all

  # list(:operations, :model => :operation_uses, :conditions => {:equipment_id => ['session[:current_equipment_id]']}, :order => "created_at ASC") do |t|
  #   t.column :name,       :through => :operation, :label => :column, :url => true
  #   t.column :planned_on, :through => :operation, :label => :column, :datatype => :date
  #   t.column :moved_on,   :through => :operation, :label => :column
  #   t.column :equipments_list, :through => :operation, :label => :column
  #   t.column :duration,   :through => :operation, :label => :column
  # end

  list(:order => "name") do |t|
    t.column :name, :url => true
    t.column :name, :through => :nature, :url => true
    # t.column :purchased_on, :datatype => :date
    # t.column :ceded_on, :datatype => :date
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  # Displays details of one equipment selected with +params[:id]+
  def show
    return unless @equipment = find_and_check(:equipment)
    session[:current_equipment_id] = @equipment.id
    t3e @equipment.attributes
  end

  # Displays the main page with the list of equipments
  def index
  end

end
