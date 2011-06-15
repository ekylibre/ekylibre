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

class LandParcelsController < ApplicationController
  manage_restfully :started_on=>"Date.today"

  list(:operations, :conditions=>{:company_id=>['@current_company.id'], :target_type=>LandParcel.name, :target_id=>['session[:current_land_parcel]']}, :order=>"planned_on ASC") do |t|
    t.column :name, :url=>true
    t.column :name, :through=>:nature
    t.column :label, :through=>:responsible, :url=>true
    t.column :planned_on
    t.column :moved_on
    t.column :tools_list
    t.column :duration
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  list(:conditions=>["#{LandParcel.table_name}.company_id=? AND ? BETWEEN #{LandParcel.table_name}.started_on AND COALESCE(#{LandParcel.table_name}.stopped_on, ?)", ['@current_company.id'], ['session[:viewed_on]'], ['session[:viewed_on]']], :order=>"name") do |t|
    t.column :name, :url=>true
    t.column :number
    t.column :area_measure, :datatype=>:decimal
    t.column :name, :through=>:area_unit
    t.column :name, :through=>:group
    t.column :description
    t.column :started_on
    t.column :stopped_on
    t.action :divide
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete
  end

  # Displays details of one land parcel selected with +params[:id]+
  def show
    return unless @land_parcel = find_and_check(:land_parcels)
    session[:current_land_parcel] = @land_parcel.id
    t3e @land_parcel.attributes
  end

  def divide
    return unless @land_parcel = find_and_check(:land_parcel)
    if request.xhr?
      render :partial=>"land_parcel_subdivision_form"
      return
    end

    if request.post?
      if @land_parcel.divide(params[:subdivisions].values, params[:land_parcel][:stopped_on].to_date)
        redirect_to :action=>:land_parcels
      end
    end
    @land_parcel.stopped_on ||= (session[:viewed_on].to_date rescue Date.today) - 1
    t3e @land_parcel.attributes
  end

  # Displays the main page with the list of land parcels
  def index
    session[:viewed_on] = (params[:viewed_on]||session[:viewed_on]).to_date rescue Date.today
    if request.post?
      land_parcels = params[:land_parcel].select{|k, v| v.to_i == 1}.collect{|k, v| @current_company.land_parcels.find(k.to_i)}
      child = land_parcels[0].merge(land_parcels[1..-1], session[:viewed_on])
      redirect_to(:action=>:land_parcel, :id=>child.id) if child
    end
  end

end
