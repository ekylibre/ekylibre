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
  class CapIsletsController < Backend::BaseController
    manage_restfully

    unroll :islet_number

    # params:
    #   :q Text search
    #   :state State search
    #   :current_campaign
    def self.cap_islets_conditions
      code = ''
      code = search_conditions(cap_islets: [:islet_number]) + " ||= []\n"
      code << "if current_campaign\n"
      code << "  c[0] << \" AND #{CapStatement.table_name}.campaign_id IN (?)\"\n"
      code << "  c << current_campaign.id\n"
      code << "end\n"
      code.c
    end

    list(conditions: cap_islets_conditions, joins: [:cap_statement], order: { islet_number: :asc }) do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :islet_number, url: true
      t.column :town_number
      t.column :net_surface_area
    end

    list(:cap_land_parcels, conditions: { cap_islet_id: 'params[:id]'.c }, order: { land_parcel_number: :asc }) do |t|
      t.column :land_parcel_number, url: true
      t.column :human_shape_area
    end

    def convert
      return unless @cap_islet = find_and_check
      if params[:to] == 'cultivable_zone'
        cultivable_zone = CultivableZone.create!(name: @cap_islet.campaign_name + '-' + @cap_islet.islet_number, shape: @cap_islet.shape)
        redirect_to params[:redirect] || { controller: :cultivable_zones, action: :show, id: cultivable_zone.id }
      else
        redirect_to backend_cap_islet(@cap_islet)
      end
    end
  end
end
