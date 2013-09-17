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

class Backend::ProductIndicatorDataController < BackendController
  manage_restfully

  unroll

 # Show a list of animals
  def index
  end

  # Show one Product with params_id
  def show
    return unless @product_indicator_datum = find_and_check
    session[:current_product_indicator_datum_id] = @product_indicator_datum.id
    t3e @product_indicator_datum
  end
end
