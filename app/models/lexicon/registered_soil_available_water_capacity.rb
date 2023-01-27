# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2021 Ekylibre SAS
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
# == Table: registered_soil_available_water_capacities
#
# id character varying PRIMARY KEY NOT NULL,
# available_water_reference_value integer,
# available_water_min_value numeric(19,4),
# available_water_max_value numeric(19,4),
# available_water_unit character varying,
# available_water_label character varying,
# shape postgis.geometry(MultiPolygon, 4326) NOT NULL
#
class RegisteredSoilAvailableWaterCapacity < LexiconRecord
  include Lexiconable
  include Ekylibre::Record::HasShape
  composed_of :available_water_max, class_name: 'Measure', mapping: [%w[available_water_max_value to_d], %w[available_water_unit unit]]
  composed_of :available_water_min, class_name: 'Measure', mapping: [%w[available_water_min_value to_d], %w[available_water_unit unit]]

  has_geometry :shape

  def name
    available_water_label
  end

end
