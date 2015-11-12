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

class Backend::CapStatementsController < Backend::BaseController
  manage_restfully

  # params:
  #   :q Text search
  #   :state State search
  #   :campaign_id
  #   :product_nature_id
  #   :storage_id
  def self.cap_statements_conditions
    code = ''
    code = search_conditions(campaigns: [:name], entities: [:full_name]) + " ||= []\n"
    code << "if current_campaign\n"
    code << "  c[0] << \" AND #{CapStatement.table_name}.campaign_id IN (?)\"\n"
    code << "  c << current_campaign.id\n"
    code << "end\n"
    code.c
  end

  list(conditions: cap_statements_conditions, joins: [:campaign, :entity]) do |t|
    t.action :edit
    t.action :destroy, if: :destroyable?
    t.column :pacage_number, url: true
    t.column :campaign, url: true
    t.column :entity, url: true
    t.column :net_surface_area
  end

  list(:cap_islets, conditions: { cap_statement_id: 'params[:id]'.c }, order: { islet_number: :desc }) do |t|
    t.column :islet_number, url: true
    t.column :town_number
    t.column :net_surface_area
  end
end
