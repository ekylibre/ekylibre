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

class SequencesController < ApplicationController
  manage_restfully :format=>"'[number|8]'", :last_number=>"0"

  list(:conditions=>{:company_id=>['@current_company.id']}) do |t|
    t.column :name
    t.column :compute
    t.column :format, :class=>:code
    t.column :period_name
    t.action :edit
    t.action :destroy, :method=>:delete, :confirm=>:are_you_sure_you_want_to_delete, :if=>"RECORD.destroyable\?"
  end

  # Displays the main page with the list of sequences
  def index
  end

  def load
    @current_company.load_sequences
    redirect_to_back
  end

end
