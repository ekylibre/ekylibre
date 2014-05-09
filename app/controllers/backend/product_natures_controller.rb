# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
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

class Backend::ProductNaturesController < BackendController
  manage_restfully

  manage_restfully_incorporation

  unroll

  # management -> product_conditions
  def self.product_natures_conditions(options={})
    code = ""
    code = search_conditions(:product_natures => [:number, :name, :commercial_name, :description, :commercial_description])+"\n"
    code << "if params[:s] == 'active'\n"
    code << "  c[0] += ' AND active = ?'\n"
    code << "  c << true\n"
    code << "elsif params[:s] == 'inactive'\n"
    code << "  c[0] += ' AND active = ?'\n"
    code << "  c << false\n"
    code << "end\n"
    code << "c\n"
    return code.c
  end

  list do |t|
    t.column :name, url: true
    t.column :category, url: true
    t.column :reference_name
    t.column :active
    t.column :variety
    t.column :derivative_of
    t.action :edit
    t.action :destroy, if: :destroyable?
  end

  list(:products, conditions: {nature_id: 'params[:id]'.c}, order: {born_at: :desc}) do |t|
    t.column :name, url: true
    t.column :identification_number
    t.column :born_at
    t.column :net_mass
    t.column :net_volume
    t.column :population
  end

  list(:product_nature_variants, conditions: {nature_id: 'params[:id]'.c}, order: :name) do |t|
    t.column :name, url: true
  end

end
