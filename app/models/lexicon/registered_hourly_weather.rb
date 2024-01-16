# frozen_string_literal: true

# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2023 Ekylibre SAS
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
# == Table: registered_hydrographic_items
#
#  id     :string           not null, primary key
#  lines  :geometry({:srid=>4326, :type=>"multi_line_string"})
#  name   :jsonb
#  nature :string
#  point  :geometry({:srid=>4326, :type=>"st_point"})
#  shape  :geometry({:srid=>4326, :type=>"multi_polygon"})
#
class RegisteredHourlyWeather < LexiconRecord
  include Lexiconable
  composed_of :station_elevation, class_name: 'Measure', mapping: [%w[elevation to_d]], constructor: proc { |value| Measure.new(value, 'meter') }
  composed_of :cumulated_rainfall, class_name: 'Measure', mapping: [%w[rain to_d]], constructor: proc { |value| Measure.new(value, 'millimeter') }
  composed_of :average_temperature, class_name: 'Measure', mapping: [%w[average_temp to_d]], constructor: proc { |value| Measure.new(value, 'celsius') }

  scope :between, lambda { |started_at, stopped_at|
    where(started_at: started_at..stopped_at)
  }

  scope :for_station_id, lambda { |station_id|
    where(station_id: station_id.to_s)
  }

  def average_temp_for_degree_day(base_temp = 6.0)
    if average_temp.present?
      if average_temp.to_d > 30.0
        (30.0 - base_temp) / 24.0
      elsif average_temp.to_d < base_temp
        nil
      else
        (average_temp.to_d - base_temp) / 24.0
      end
    else
      nil
    end
  end

end
