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

class VegetalsController < AdminController
  manage_restfully

  respond_to :pdf, :xml, :json, :html

  unroll_all

  list do |t|
    t.column :name, :url => true
    t.column :born_at
    t.action :show, :url => {:format => :pdf}, :image => :print
    t.action :edit
    t.action :destroy, :if => "RECORD.destroyable\?"
  end

  # Show a list of animal groups

  def index
    @vegetal = Vegetal.all
    #parsing a parameter to Jasper for company full name
    @entity_full_name = Entity.of_company.full_name
    #respond with associated models to simplify quering in Ireport
    respond_with @vegetal
  end


  # Show one vegetal with params_id
  def show
    return unless @vegetal = find_and_check
    respond_to do |format|
      format.html do
        session[:current_vegetal_id] = @vegetal.id
        t3e @vegetal
      end
      format.xml {render xml: @vegetal }
      format.pdf {respond_with @vegetal }
    end
  end

end
