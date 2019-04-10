# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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
  class TaxesController < Backend::BaseController
    manage_restfully

    unroll

    list do |t|
      t.action :edit
      t.action :destroy
      t.column :active
      t.column :name, url: true
      t.column :amount, precision: 3
      t.column :nature
      t.column :intracommunity
      t.column :country
      t.column :deduction_account, url: true, label_method: :number
      t.column :collect_account, url: true, label_method: :number
      t.column :fixed_asset_deduction_account, url: true, hidden: true, label_method: :number
      t.column :fixed_asset_collect_account, url: true, hidden: true, label_method: :number
    end

    def load
      Tax.clean!
      Tax.import_all_from_nomenclature(active: true)
      redirect_to params[:redirect] || { action: :index }
    end
  end
end
