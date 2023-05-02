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
# == Table: registered_cadastral_prices
#
#  address               :string
#  building_area         :integer(4)
#  building_nature       :string
#  cadastral_parcel_area :integer(4)
#  cadastral_parcel_id   :string
#  cadastral_price       :decimal(14, 2)
#  centroid              :geometry({:srid=>4326, :type=>"st_point"})
#  city                  :string
#  department            :string
#  id                    :integer(4)       not null, primary key
#  mutation_date         :date
#  mutation_id           :string
#  mutation_nature       :string
#  mutation_reference    :string
#  postal_code           :string
#
class RegisteredCadastralPrice < LexiconRecord
  include Lexiconable
  scope :in_bounding_box, lambda { |bounding_box|
    where("registered_cadastral_prices.centroid && ST_MakeEnvelope(#{bounding_box.join(', ')})")
  }

  def centroid
    ::Charta.new_geometry(self[:centroid])
  end
end
