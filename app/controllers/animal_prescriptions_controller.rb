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

class AnimalPrescriptionsController < AdminController
  manage_restfully

  unroll

  list() do |t|
    t.column :name, :url=>true
    t.column :name, :through=>:prescriptor, :url=>true
    t.column :prescription_number
    t.column :prescripted_on
    t.action :show, :url=>{:format=>:pdf}, :image=>:print
    t.action :edit
    t.action :destroy, :if=>"RECORD.destroyable\?"
  end

  # Show a list of @prescription
  def index
  end

  # Show one prescription with params_id
  def show
    return unless @animal_prescription = find_and_check
    session[:current_animal_prescription_id] = @animal_prescription.id
    t3e @animal_prescription
  end

end
