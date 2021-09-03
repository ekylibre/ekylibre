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
# == Table: cadastral_land_parcel_zones
#
#  centroid         :geometry({:srid=>4326, :type=>"st_point"})
#  id               :string           not null, primary key
#  net_surface_area :integer
#  section          :string
#  shape            :geometry({:srid=>4326, :type=>"multi_polygon"}) not null
#  work_number      :string
#
class RegisteredGraphicParcel < LexiconRecord
  include Lexiconable

  def shape
    ::Charta.new_geometry(self[:shape])
  end

  scope :in_bounding_box, lambda { |bounding_box|
    where("registered_graphic_parcels.shape && ST_MakeEnvelope(#{bounding_box})")
  }

  scope :without_intersected_with_selection, ->(*selected_ids){
    joins(<<~SQL).where('selecteds.id IS NULL')
      LEFT JOIN (#{RegisteredGraphicParcel.where(id: selected_ids).to_sql}) AS selecteds
      ON (ST_INTERSECTS(registered_graphic_parcels.shape, selecteds.shape)
        AND NOT ST_TOUCHES(registered_graphic_parcels.shape, selecteds.shape))
        AND registered_graphic_parcels.id != selecteds.id
    SQL
  }

  scope :without_intersected_with_shape, ->(shape){
    joins(<<~SQL).where('rgp.intersect_with_shape = FALSE')
      LEFT JOIN (SELECT (ST_INTERSECTS(registered_graphic_parcels.shape, '#{shape}')
                        AND NOT ST_TOUCHES(registered_graphic_parcels.shape, '#{shape}')) AS intersect_with_shape,
                        id
                FROM registered_graphic_parcels) as rgp
                ON registered_graphic_parcels.id = rgp.id
    SQL
  }
end
