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

class AnimalsController < ApplicationController
  manage_restfully
  
  list(:conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :ident_number, :url=>{:action=>:show}
    t.column :name, :url=>true
    t.column :name, :through=>:animal_group, :url=>true
    t.column :born_on
    t.column :sexe
    t.column :comment
    t.column :description
    t.column :in_on
    t.column :out_on
    t.action :show, :url=>{:format=>:pdf}, :image=>:print
    t.action :edit
    t.action :destroy, :if=>"RECORD.destroyable\?"
  end
  
  # Show a list of animal groups
  def index
  end
  
  # Show one Groups of animals with params_id
  def show
    return unless @animal = find_and_check
    session[:current_animal_id] = @animal.id   
    t3e @animal
  end
  
end
