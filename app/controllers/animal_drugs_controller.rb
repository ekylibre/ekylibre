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

class AnimalDrugsController < AdminController
  manage_restfully
  unroll :label => "{name}"
  list() do |t|
    t.column :name, :url=>true
    t.column :name, :through=>:unit, :url=>true
    t.column :name, :through=>:nature, :url=>true
    t.column :frequency
    t.column :quantity
    t.column :comment
    t.action :show, :url=>{:format=>:pdf}, :image=>:print
    t.action :edit
    t.action :destroy, :if=>"RECORD.destroyable\?"
  end

  # Show a list of animals natures
  def index
  end

  # Show one care with params_id
  def show
    return unless @animal_drug = find_and_check(:animal_drug)
    session[:current_animal_drug_id] = @animal_drug.id
    t3e @animal_drug
  end

end
