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
  class SubscriptionNaturesController < Backend::BaseController
    manage_restfully

    unroll

    list do |t|
      t.action :edit
      t.action :destroy
      t.column :name, url: true
      t.column :description
    end

    list(:subscriptions, conditions: { nature_id: 'params[:id]'.c }, order: { started_on: :desc }) do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :subscriber, url: true
      t.column :coordinate, through: :address, url: true
      # t.column :product_nature
      t.column :quantity
      t.column :sale
      t.column :started_on
      t.column :stopped_on
    end

    list(:product_natures, conditions: { subscription_nature_id: 'params[:id]'.c }) do |t|
      t.action :edit, url: { controller: '/backend/product_natures' }
      t.action :destroy, url: { controller: '/backend/product_natures' }
      t.column :number, url: { controller: '/backend/product_natures' }
      t.column :name, url: { controller: '/backend/product_natures' }
      t.column :subscribing
      t.column :subscription_duration
    end
  end
end
