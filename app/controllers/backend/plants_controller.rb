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
  manage_restfully :t3e => {:nature_name => "@plant.nature_name"}

  respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

  unroll_all

  list(:conditions => [" external = false"]) do |t|
    t.column :work_number, :url => true
    t.column :name, :url => true
    t.column :born_at
    t.action :edit
    t.action :destroy, :if => :destroyable?
  end

  # Show a list of animal groups

  def index
    @plants = Plant.all
    #parsing a parameter to Jasper for company full name
    #respond with associated models to simplify quering in Ireport
    respond_with @plants, :include => [:variety, :nature]
  end


  # Show one vegetal with params_id
  def show
    return unless @plant = find_and_check
    respond_to do |format|
      format.html do
        session[:current_vegetal_id] = @plant.id
        t3e @plant
      end
      format.xml {render xml: @plant }
      format.pdf {respond_with @plant }
    end
  end

  def picture
    return unless @plant = find_and_check
    send_file @plant.picture.path(params[:style] || :original)
  end

end
