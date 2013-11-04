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

class Backend::AnimalsController < Backend::ProductsController
  manage_restfully :t3e => {:nature_name => :nature_name}

  respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

  unroll

  list() do |t|
    t.column :work_number, url: true
    t.column :name, url: true
    t.column :born_at
    t.column :sex
    t.column :weight
    t.column :localize_in
    t.column :mother, url: true
    t.column :father, url: true
    t.action :show, :url => {:format => :pdf}, :image => :print
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
  list(:children, :model => :animals, :conditions => ["mother_id = ? OR father_id = ?", 'params[:id]'.c, 'params[:id]'.c], :order => "born_at DESC") do |t|
    t.column :name, url: true
    t.column :born_at
    t.column :sex
    t.column :description
  end

  # Liste des lieux de l'animal considéré
  list(:places, :model => :product_localizations, :conditions => {product_id: 'params[:id]'.c}, :order => "started_at DESC") do |t|
    t.column :container, url: true
    t.column :nature
    t.column :started_at
    t.column :arrival_cause
    t.column :stopped_at
    t.column :departure_cause
  end

  # Liste des groupes de l'animal considéré
  list(:groups, :model => :product_memberships, :conditions => {member_id: 'params[:id]'.c}, :order => "started_at DESC") do |t|
    t.column :group, url: true
    t.column :started_at
    t.column :stopped_at
  end

  # Liste des indicateurs de l'animal considéré
  list(:indicators, :model => :product_indicator_data, :conditions => {product_id: 'params[:id]'.c}, :order => "created_at DESC") do |t|
    t.column :indicator_name
    t.column :measured_at
    t.column :value
  end

  # Liste des incidents de l'animal considéré
  list(:incidents, :model => :incidents, :conditions => {target_id: 'params[:id]'.c, target_type: 'Animal'}, :order => "observed_at DESC") do |t|
    t.column :name, url: true
    t.column :nature
    t.column :observed_at
    t.column :gravity
    t.column :priority
    t.column :state
  end

  list(:intervention_casts, :conditions => {actor_id: 'params[:id]'.c}) do |t|
    t.column :intervention, url: true
    t.column :roles
    t.column :variable
    t.column :started_at, through: :intervention
    t.column :stopped_at, through: :intervention
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


  def picture
    return unless @animal = find_and_check
    send_file @animal.picture.path(params[:style] || :original)
  end

end
