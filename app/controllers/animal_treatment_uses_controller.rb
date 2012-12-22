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

class AnimalTreatmentUsesController < AdminController
  manage_restfully

  list() do |t|
    t.column :name, :url=>true
    t.column :started_on, :through=>:event
    t.column :name, :through=>:drug_allowed
    t.column :quantity
    t.column :name, :through=>:event, :url=>true
    t.column :name, :through=>:treatment, :url=>true
    t.column :quantity, :through=>:treatment
    t.action :edit
    t.action :destroy, :if=>"RECORD.destroyable\?"
  end

  # Show a list of animal_treatment_use
  def index
  end

  # Show one care with params_id
  def show
    return unless @animal_treatment_use = find_and_check
    session[:current_animal_treatment_use_id] = @animal_treatment_use.id
    t3e @animal_treatment_use
  end

end
