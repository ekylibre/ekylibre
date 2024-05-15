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

    def self.taxes_conditions
      code = search_conditions(taxes: %i[amount reference_name name nature country], accounts: %i[number name]) + " ||= []\n"
      code << "if params[:state].present?\n"
      code << "  if params[:state] == 'active'\n"
      code << "    c[0] << ' AND #{Tax.table_name}.active = TRUE'\n"
      code << "  elsif params[:state] == 'inactive'\n"
      code << "    c[0] << ' AND #{Tax.table_name}.active = FALSE'\n"
      code << "  end\n"
      code << "end\n"
      code << "if params[:provider].present?\n"
      code << "  c[0] += \" AND \#{Tax.table_name}.provider ->> 'vendor' = ?\"\n"
      code << "  c << params[:provider].tap { |e| e[0] = e[0].downcase }.to_s\n"
      code << "end\n"
      code << "c\n "
      code.c
    end

    list(conditions: taxes_conditions, joins: %i[collect_account deduction_account]) do |t|
      t.action :edit
      t.action :destroy
      t.column :active
      t.column :name, url: true
      t.column :amount, precision: 2
      t.column :nature
      t.column :intracommunity
      t.column :country
      t.column :deduction_account, url: true, label_method: :number
      t.column :collect_account, url: true, label_method: :number
      t.column :fixed_asset_deduction_account, url: true, hidden: true, label_method: :number
      t.column :fixed_asset_collect_account, url: true, hidden: true, label_method: :number
      t.column :collect_isacompta_code, hidden: true
      t.column :deduction_isacompta_code, hidden: true
      t.column :fixed_asset_deduction_isacompta_code, hidden: true
      t.column :fixed_asset_collect_isacompta_code, hidden: true
      t.column :provider_vendor, label_method: 'provider_vendor&.capitalize', hidden: true
    end

    def load
      Tax.clean!
      Tax.import_all_from_nomenclature(active: true)
      redirect_to params[:redirect] || { action: :index }
    end
  end
end
