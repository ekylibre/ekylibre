# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2013 David Joulin, Brice Texier
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

module Backend
  class CapLandParcelsController < Backend::BaseController
    manage_restfully

    # params:
    #   :q Text search
    #   :state State search
    #   :current_campaign
    def self.cap_land_parcels_conditions
      code = ''
      code = search_conditions(cap_land_parcels: [:land_parcel_number]) + " ||= []\n"
      code << "if current_campaign\n"
      code << "  c[0] << \" AND #{CapStatement.table_name}.campaign_id IN (?)\"\n"
      code << "  c << current_campaign.id\n"
      code << "end\n"
      code.c
    end

    list(conditions: cap_land_parcels_conditions, joins: [:cap_statement], order: { land_parcel_number: :asc }) do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :land_parcel_number, url: true
      t.column :islet_number, through: :cap_islet, url: true
      t.column :main_crop_code
      t.column :main_crop_precision
      t.column :net_surface_area
    end
  end
end
