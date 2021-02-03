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
# == Table: registered_postal_zones
#
#  city_centroid        :geometry({:srid=>4326, :type=>"st_point"})
#  city_delivery_detail :string
#  city_delivery_name   :string
#  city_name            :string           not null
#  code                 :string           not null
#  country              :string           not null
#  id                   :string           not null, primary key
#  postal_code          :string           not null
#
class RegisteredPostalZone < LexiconRecord
  include Lexiconable
  self.id_column = :code
end
