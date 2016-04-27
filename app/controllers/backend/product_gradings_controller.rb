# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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

module Backend
  class ProductGradingsController < Backend::BaseController

     manage_restfully

     unroll

    list do |t|
      t.action :edit
      t.action :destroy
      t.column :activity
      t.column :product
      t.column :number, url: true
      t.column :sampled_at, datatype: :datetime
      t.column :implanter_rows_number
      t.column :implanter_working_width
    end

    list(:items, model: :product_grading_checks, conditions: { product_grading_id: 'params[:id]'.c }) do |t|
      t.action :edit
      t.action :destroy
      t.column :activity_grading_check, label_method: :name
      t.column :items_count
      t.column :net_mass_value
      t.column :minimal_size_value
      t.column :maximal_size_value
    end

  end
end