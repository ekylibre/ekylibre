# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
# == Table: registered_hydro_items
#
#  id     :string           not null, primary key
#  lines  :geometry({:srid=>4326, :type=>"multi_line_string", :has_z=>true, :has_m=>true})
#  name   :jsonb
#  nature :string
#  point  :geometry({:srid=>4326, :type=>"st_point"})
#  shape  :geometry({:srid=>4326, :type=>"multi_polygon", :has_z=>true, :has_m=>true})
#
class RegisteredHydroItem < ActiveRecord::Base
  include Lexiconable

  scope :in_bounding_box, lambda { |bounding_box|
    where(<<-SQL)
      registered_hydro_items.shape && ST_MakeEnvelope(#{bounding_box.join(', ')})
      OR registered_hydro_items.lines && ST_MakeEnvelope(#{bounding_box.join(', ')})
      OR registered_hydro_items.point && ST_MakeEnvelope(#{bounding_box.join(', ')})
    SQL
  }

end
