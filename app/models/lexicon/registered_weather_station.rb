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
# == Table: registered_weather_stations
#
#  reference_name :string           not null, primary key
#  country        :string
#  country_zone   :string
#  station_code   :string
#  station_name   :string
#  elevation      :integer
#  centroid       :geometry({:srid=>4326, :type=>"st_point"})
#
class RegisteredWeatherStation < LexiconRecord
  include Lexiconable
  include Ekylibre::Record::HasShape

  has_geometry :centroid, type: :point

  scope :of_country, ->(country) { where(country: country.to_s.upper) }

  scope :of_country_zone, ->(country_zone) { where(country_zone: country_zone.to_s) }

  scope :in_bounding_box, lambda { |bounding_box|
    where(<<-SQL)
      registered_hourly_weathers.centroid && ST_MakeEnvelope(#{bounding_box})
    SQL
  }

  # TODO: improve this once PostGIS has been updated to 2.5 as ST_Intersects now supports GEOMETRYCOLLECTION
  scope :buffer_intersecting, lambda { |buffer, *geometries|
    union = geometries.reduce { |geometry, union| union.merge(geometry) }
    bounding_box = Charta.new_geometry(union).buffer(buffer).bounding_box

    in_bounding_box(bounding_box.to_bbox_string)
      .where("ST_Intersects(ST_Buffer(centroid::geography, #{buffer}), '#{union}')")
  }

  def name
    "#{reference_name} - #{station_name}"
  end

end
