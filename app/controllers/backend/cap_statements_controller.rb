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
  class CapStatementsController < Backend::BaseController
    manage_restfully

    unroll :farm_name, :pacage_number, :siret_number, campaign: [:name]

    # params:
    #   :q Text search
    #   :state State search
    #   :campaign_id
    #   :product_nature_id
    #   :storage_id
    def self.list_conditions
      code = ''
      code = search_conditions(campaigns: [:name], entities: [:full_name]) + " ||= []\n"
      # code << "if current_campaign\n"
      # code << "  c[0] << \" AND #{CapStatement.table_name}.campaign_id IN (?)\"\n"
      # code << "  c << current_campaign.id\n"
      # code << "end\n"
      code.c
    end

    def self.cap_land_parcel_conditions
      code = ''
      code = search_conditions(cap_land_parcels: [:land_parcel_number, :main_crop_code]) + " ||= []\n"
      code << "if params[:id].to_i > 0\n"
      code << "  c[0] << \" AND #{CapStatement.table_name}.id IN (?)\"\n"
      code << "  c << params[:id].to_i\n"
      code << "end\n"
      code.c
    end

    list(conditions: list_conditions, joins: [:campaign, :declarant]) do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :pacage_number, url: true
      t.column :campaign, url: true
      t.column :declarant, url: true
      t.column :farm_name, url: true
      t.column :net_surface_area, label_method: :human_net_surface_area
    end

    list(:cap_islets, conditions: { cap_statement_id: 'params[:id]'.c }, order: { islet_number: :desc }) do |t|
      t.column :islet_number, url: true
      t.column :town_number
      t.column :human_shape_area, datatype: :measure
    end

    list(:cap_land_parcels, conditions: cap_land_parcel_conditions, joins: :cap_statement, order: { land_parcel_number: :desc }) do |t|
      t.column :land_parcel_number, url: true
      t.column :islet_number
      t.column :main_crop_code
      t.column :main_crop_commercialisation
      t.column :main_crop_seed_production
      t.column :main_crop_precision
      t.column :human_shape_area, datatype: :measure
    end
  end
end
