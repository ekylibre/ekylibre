# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2018 Brice Texier, David Joulin
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
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: products_yield_observations
#
#  id                   :integer          not null, primary key
#  product_id           :integer          not null
#  working_zone         :geometry({:srid=>4326, :type=>"geometry"})
#  yield_observation_id :integer          not null
#
class ProductsYieldObservation < ApplicationRecord
  belongs_to :yield_observation # , required: true
  belongs_to :vegetative_stage # , required: true
  belongs_to :plant, class_name: 'Product', foreign_key: :product_id, required: true
  has_many :pyo_issues, class_name: 'Issue', foreign_key: :products_yield_observation_id, dependent: :destroy

  accepts_nested_attributes_for :pyo_issues, allow_destroy: true

  has_geometry :working_zone

  before_validation do
    self.working_zone = plant.shape if plant
    true
  end
end
