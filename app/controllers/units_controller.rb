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

class UnitsController < ApplicationController
  manage_restfully :base=>"params[:base]"

  list(:conditions=>{:company_id=>["@current_company.id"]}, :order=>:name) do |t|
    t.column :label
    t.column :name
	t.column :coefficient, :datatype=>:numeric
    t.column :base
    t.column :start
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end

  # Displays the main page with the list of units
  def index
  end

  def load
    @current_company.load_units
    redirect_to :action=>:index
  end

end
