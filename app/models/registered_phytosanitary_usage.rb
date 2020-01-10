# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2019 Brice Texier, David Joulin
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
# == Table: registered_phytosanitary_usages
#
#  applications_count        :integer          not null
#  applications_frequency    :jsonb
#  description               :jsonb
#  dose_quantity             :decimal(19, 4)   not null
#  dose_unit                 :string
#  dose_unit_name            :string
#  pre_harvest_delay         :integer          not null
#  product_id                :integer          not null
#  specie                    :string           not null
#  target_name               :jsonb
#  treatment                 :jsonb
#  untreated_buffer_distance :integer
#
class RegisteredPhytosanitaryUsage < ActiveRecord::Base
  include Lexiconable
  belongs_to :product, class_name: 'RegisteredPhytosanitaryProduct'

  scope :of_specie, ->(specie) { where(specie: specie.to_s) }
end
