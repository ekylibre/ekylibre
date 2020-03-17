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
  class CatalogsController < Backend::BaseController
    unroll

    manage_restfully

    list do |t|
      t.action :edit
      t.action :destroy
      t.column :code, url: true
      t.column :name, url: true
      t.column :usage
      t.column :currency, url: true
      t.column :all_taxes_included, url: true
      t.column :description, hidden: true
      t.column :by_default
    end

    list(:items, model: :catalog_items, conditions: { catalog_id: 'params[:id]'.c }) do |t|
      t.action :edit
      t.action :destroy
      t.column :name, url: true
      t.column :variant, url: { controller: 'RECORD.variant.class.name.tableize'.c, namespace: :backend }
      t.column :amount, currency: true
      t.column :all_taxes_included
      t.column :reference_tax, url: true
    end
  end
end
