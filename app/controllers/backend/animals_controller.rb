# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2012-2013 David Joulin, Brice Texier
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

class Backend::AnimalsController < Backend::MattersController

  list do |t|
    t.column :work_number, url: true
    t.column :name, url: true
    t.column :born_at
    t.column :sex
    t.column :net_mass
    t.column :container, url: true
    t.column :mother, url: true
    t.column :father, url: true
    t.action :show, url: {:format => :pdf}, image: :print
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  # Show a list of animal groups

  def index
    @animals = Animal.all
    # parsing a parameter to Jasper for company full name
    @entity_full_name = Entity.of_company.full_name
    # respond with associated models to simplify quering in Ireport
    respond_with @animals, :include => [:father, :mother, :variety, :nature]
  end

   # Liste des enfants de l'animal considéré
  list(:children, model: :animals, conditions: ["mother_id = ? OR father_id = ?", 'params[:id]'.c, 'params[:id]'.c], order: {born_at: :desc}) do |t|
    t.column :name, url: true
    t.column :born_at
    t.column :sex
    t.column :description
  end

  # Show one animal with params_id
  def show
    return unless @animal = find_and_check
    session[:current_animal_id] = @animal.id
    t3e @animal, :nature_name => @animal.nature_name
           respond_with(@animal, :methods => :picture_path, :include => [:father, :mother, :variant, :nature, :variety,
                                                   {:indicator_data => {}},
                                                   {:memberships => {:include =>:group}},
                                                   {:localizations => {:include =>:container}}])

  end

end
