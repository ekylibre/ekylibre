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

class TaxesController < AdminController
  manage_restfully :nature=>":percent"

  unroll

  list do |t|
    t.column :name
    t.column :amount, :precision=>3
    t.column :nature_label
    t.column :included
    t.column :reductible
    t.column :label, :through=>:paid_account, :url=>true
    t.column :label, :through=>:collected_account, :url=>true
    t.action :edit
    t.action :destroy
  end

  # Displays the main page with the list of taxes
  def index
  end

end
