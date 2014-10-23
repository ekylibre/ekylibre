# -*- coding: utf-8 -*-
# == License
# Ekylibre ERP - Simple agricultural ERP
# Copyright (C) 2014 Brice Texier, David Joulin
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

class Backend::AnimalProductsController < BackendController

  list model: :products, scope: [:availables, "of_variety(:matter)".c, "derivative_of(:animal)".c] do |t|
    t.column :number, url: true
    t.column :name, url: true
    t.column :net_mass, datatype: :measure
    t.column :container, url: true
    t.action :edit
    t.action :destroy, if: :destroyable?
  end

  def index
  end

end
