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

class Backend::FixedAssetsController < Backend::BaseController
  manage_restfully currency: 'Preference[:currency]'.c, depreciation_method: 'linear'

  unroll

  list do |t|
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
  #   redirect_to fixed_asset_url(@fixed_asset)
  # end
end
