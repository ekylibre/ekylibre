# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2012 Brice Texier
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

class PurchaseNaturesController < AdminController
  manage_restfully :currency=>"Entity.of_company.currency"

  unroll_all

  list do |t|
    t.column :name, :url=>true
    t.column :active
    t.column :currency
    t.column :with_accounting
    t.column :name, :through=>:journal, :url=>true
    t.action :edit
    t.action :destroy
  end

  # Displays the main page with the list of purchase natures
  def index
  end

  def show
    return unless @purchase_nature = find_and_check
    t3e @purchase_nature
  end
end
