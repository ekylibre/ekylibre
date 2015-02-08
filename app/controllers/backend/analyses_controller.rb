# encoding: utf-8
# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2013 Brice Texier, David Joulin
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

class Backend::AnalysesController < Backend::BaseController
  manage_restfully

  unroll

  list do |t|
    t.column :number, url: true
    t.column :reference_number, url: true
    t.column :nature
    t.column :product, url: true
    t.column :analyser, url: true
    t.column :analysed_at
    t.column :sampled_at, hidden: true
    t.column :sampler, url: true, hidden: true
  end

  list :items, model: :analysis_items, conditions: {analysis_id: 'params[:id]'.c} do |t|
    t.column :indicator, datatype: :item
    t.column :value, datatype: :measure
    t.column :annotation
  end

end
