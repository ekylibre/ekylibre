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
  class CatalogItemsController < Backend::BaseController
    manage_restfully except: [:index, :new], destroy_to: '{controller: :catalogs, action: :show, id: RECORD.catalog_id}'.c, continue: [:variant_id]

    unroll

    def new
      @catalog_item = CatalogItem.new(catalog_id: params[:catalog_id], variant_id: params[:variant_id])
      render locals: { with_continue: true, cancel_url: :backend_catalogs }
    end

    list do |t|
      t.action :edit
      t.action :destroy
      t.column :name, url: true
      t.column :variant, url: { controller: 'RECORD.variant.class.name.tableize'.c, namespace: :backend }
      t.column :amount, currency: true
      t.column :reference_tax, url: true
      t.column :all_taxes_included
      t.column :catalog, url: true
    end
  end
end
