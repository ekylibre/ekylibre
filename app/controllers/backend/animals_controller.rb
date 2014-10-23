# -*- coding: utf-8 -*-
# == License
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2012-2013 David Joulin, Brice Texier
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::AnimalsController < Backend::MattersController

  # params:
  #   :q Text search
  #   :s State search
  #   :variant_id
  def self.animals_conditions
    code = ""
    code = search_conditions(:product_nature_variants => [:name]) + " ||= []\n"
    code << "  if params[:variant_id].to_i > 0\n"
    code << "    c[0] << \" AND \#{ProductNatureVariant.table_name}.id = ?\"\n"
    code << "    c << params[:variant_id].to_i\n"
    code << "  end\n"
    code << "c\n "
    return code.c
  end

  list(conditions: animals_conditions, joins: :variant) do |t|
    t.column :work_number, url: true
    t.column :name, url: true
    t.column :born_at
    t.column :sex
    t.status
    t.column :net_mass, datatype: :measure
    t.column :container, url: true
    #t.column :groups, url: true
    t.column :mother, url: true, hidden: true
    t.column :father, url: true, hidden: true
    # t.action :show, url: {format: :pdf}, image: :print
    t.action :new,     on: :none
    # t.action :new_issue,        on: :both, url: {action: :new, controller: :issues}
    # t.action :new_intervention, on: :both, url: {action: :new, controller: :interventions}
    t.action :edit
    t.action :destroy
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
  list(:children, model: :product_links, conditions: {linked_id: 'params[:id]'.c, nature: %w(father mother)}, order: {started_at: :desc}) do |t|
    t.column :name, through: :product, url: true
    t.column :born_at, through: :product
    t.column :sex, through: :product
  end

  # Show one animal with params_id
  def show
    return unless @animal = find_and_check
    t3e @animal, nature: @animal.nature_name
    respond_with(@animal, :methods => [:picture_path, :sex_text], :include => [:father, :mother, :variant, :nature, :variety,
                                                                  {:readings => {}},
                                                                  {:intervention_casts => {:include => :intervention}},
                                                                  {:memberships => {:include => :group}},
                                                                  {:localizations => {:include => :container}}])

  end

end
