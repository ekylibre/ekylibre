# coding: utf-8
# == License
# Ekylibre ERP - Simple agricultural ERP
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

class Backend::CatalogPricesController < BackendController
  manage_restfully indicator_name: "params[:indicator_name] || 'population'".c, started_at: "params[:started_at] || Time.now".c

  unroll

  list do |t|
    t.column :variant, url: true
    t.column :amount
    t.column :started_at
    t.column :stopped_at
    t.column :reference_tax, url: true
    t.column :all_taxes_included
    t.column :catalog, url: true
    t.action :stop, method: :post, confirm: true
    t.action :edit
    t.action :destroy, if: :destroyable?
  end

  def stop
    return unless @catalog_price = find_and_check
    @catalog_price.stop
    redirect_to params[:redirect] || {action: :show, id: @catalog_price.id}
  end

end
