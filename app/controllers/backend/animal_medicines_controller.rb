# coding: utf-8
# == License
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2008-2013 David Joulin, Brice Texier
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

class Backend::AnimalMedicinesController < BackendController

  list model: :products, scope: "of_working_set(:animal_medicines)".c do |t|
    t.column :name, url: true
    t.column :population, datatype: :decimal
    t.column :net_volume, datatype: :measure, hidden: true
    t.column :net_mass, datatype: :measure
    t.column :container, url: true
    t.column :milk_withdrawal_period, datatype: :measure, hidden: true
    t.column :meat_withdrawal_period, datatype: :measure, hidden: true
  end

  def index
  end

end
