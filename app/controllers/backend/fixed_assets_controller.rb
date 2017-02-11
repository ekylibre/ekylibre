# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2012 Brice Texier
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
  class FixedAssetsController < Backend::BaseController
    manage_restfully currency: 'Preference[:currency]'.c, depreciation_method: 'linear'

    unroll
    
    # params:
    #   :q Text search
    #   :s State search
    #   :period Two Dates with _ separator
    #   :variant_id
    #   :activity_id
    def self.fixed_assets_conditions
      code = ''
      code = search_conditions(fixed_assets: [:name, :description]) + " ||= []\n"
      code << "if params[:period].present? && params[:period].to_s != 'all'\n"
      code << "  c[0] << ' AND #{FixedAsset.table_name}.started_on BETWEEN ? AND ?'\n"
      code << "  if params[:period].to_s == 'interval'\n"
      code << "    c << params[:started_on]\n"
      code << "    c << params[:stopped_on]\n"
      code << "  else\n"
      code << "    interval = params[:period].to_s.split('_')\n"
      code << "    c << interval.first\n"
      code << "    c << interval.second\n"
      code << "  end\n"
      code << "end\n"
      code << "if params[:fixed_asset_id].to_i > 0\n"
      code << "  c[0] += ' AND #{FixedAsset.table_name}.id = ?'\n"
      code << "  c << params[:fixed_asset_id]\n"
      code << "end\n"
      code << "c\n"
      code.c
    end

    list(conditions: fixed_assets_conditions, left_joins: :products) do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :name, url: true
      t.column :depreciable_amount, currency: true
      t.column :started_on
      t.column :stopped_on
    end

    list(:depreciations, model: :fixed_asset_depreciations, conditions: { fixed_asset_id: 'params[:id]'.c }, order: :position) do |t|
      # t.action :edit, if: "RECORD.journal_entry.nil?".c
      t.column :amount, currency: true
      t.column :depreciable_amount, currency: true
      t.column :depreciated_amount, currency: true
      t.column :started_on
      t.column :stopped_on
      t.column :financial_year, url: true
      t.column :journal_entry, label_method: :number, url: true
    end

    list(:products, model: :products, conditions: { fixed_asset_id: 'params[:id]'.c }, order: :initial_born_at) do |t|
      t.column :name, url: true
      t.column :initial_born_at
    end

    # def cede
    #   return unless @fixed_asset = find_and_check
    # end

    # def sell
    #   return unless @fixed_asset = find_and_check
    # end

    # def depreciate
    #   return unless @fixed_asset = find_and_check
    #   @fixed_asset.depreciate!
    #   redirect_to fixed_asset_path(@fixed_asset)
    # end
  end
end
