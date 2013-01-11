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

class AnimalsController < AdminController
  manage_restfully

  respond_to :pdf, :xml, :json, :html

  unroll_all

  list do |t|
    t.column :work_number, :url => true
    t.column :name, :url=>true
    t.column :name, :through=>:group, :url=>true
    t.column :born_on
    t.column :sex
    t.column :name, :through=>:mother, :url=>true
    t.column :name, :through=>:father, :url=>true
    t.column :departed_on
    t.column :departure_reasons
    t.action :show, :url=>{:format=>:pdf}, :image=>:print
    t.action :edit
    t.action :destroy, :if=>"RECORD.destroyable\?"
  end

  # Show a list of animal groups

  def index
    @animal = Animal.all
    #parsing a parameter to Jasper for company full name
    @entity_full_name = Entity.of_company.full_name
    #respond with associated models to simplify quering in Ireport
    respond_with @animal, :include => [:race , :father, :mother]
  end

  # Liste des soins de l'animal considéré
  list(:events, :model=>:animal_events, :conditions=>{:animal_id=>['session[:current_animal_id]']}, :order=>"started_at ASC") do |t|
    t.column :name, :url=>true
    t.column :name ,:through => :nature
    t.column :name ,:through => :watcher
    t.column :started_at
    t.column :comment
  end

  # Liste des enfants de l'animal considéré
  list(:children, :model=>:animal, :conditions=>[" mother_id = ? OR father_id = ? ",['session[:current_animal_id]'],['session[:current_animal_id]']], :order=>"born_on DESC") do |t|
    t.column :name, :url=>true
    t.column :born_on
    t.column :sex
    t.column :comment
  end

  # Show one animals with params_id
  def show
    respond_to do |format|
      return unless @animal = find_and_check(:animal)
      format.html do
        session[:current_animal_id] = @animal.id
        t3e @animal
      end
      format.xml {render xml: @animal, :include => [:race, :father, :mother, :group, :events]}
      format.pdf {respond_with @animal, :include => [:race, :father, :mother, :group, :events]}
    end
  end

end
