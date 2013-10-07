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

class Backend::PlantsController < BackendController
  manage_restfully :t3e => {:nature_name => :nature_name}

  respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

  unroll

  list() do |t|
    t.column :work_number, url: true
    t.column :name, url: true
    t.column :born_at
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  # Liste du lieu de la plante considérée
  list(:places, :model => :product_localizations, :conditions => {product_id: 'params[:id]'.c}, :order => "started_at DESC") do |t|
    t.column :name, through: :container, url: true
    t.column :nature
    t.column :started_at
    t.column :stopped_at
  end

  # Liste des indicateurs de la plante considérée
  list(:indicators, :model => :product_indicator_data, :conditions => {product_id: 'params[:id]'.c}, :order => "created_at DESC") do |t|
    t.column :indicator
    t.column :measured_at
    t.column :value
    t.column :measure_unit
  end

  # Liste des incidents de la plante considérée
  list(:incidents, :conditions => {target_id: 'params[:id]'.c, target_type: 'Plant'}, :order => "observed_at DESC") do |t|
    t.column :name, url: true
    t.column :nature
    t.column :observed_at
    t.column :gravity
    t.column :priority
    t.column :state
  end

  list(:intervention_casts, :conditions => {actor_id: 'params[:id]'.c}) do |t|
    t.column :name, through: :intervention, url: true
    t.column :roles
    t.column :variable
    t.column :started_at, through: :intervention
    t.column :stopped_at, through: :intervention
  end


  # def index
  #   @plants = Plant.all
  #   #parsing a parameter to Jasper for company full name
  #   #respond with associated models to simplify quering in Ireport
  #   respond_with @plants, :include => [:variety, :nature]
  # end


  # Show one vegetal with params_id
  # def show
  #   return unless @plant = find_and_check
  #   respond_to do |format|
  #     format.html do
  #       session[:current_plant_id] = @plant.id
  #       t3e @plant
  #     end
  #     format.xml {render xml: @plant }
  #     format.pdf {respond_with @plant }
  #   end
  # end

  def picture
    return unless @plant = find_and_check
    send_file @plant.picture.path(params[:style] || :original)
  end

end
