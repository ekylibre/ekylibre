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
  class InventoriesController < Backend::BaseController
    manage_restfully except: %i[index show], achieved_at: 'Time.zone.now'.c, responsible_id: 'current_user.person.id'.c, name: 'Time.zone.now.year.to_s'.c

    respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

    unroll

    list do |t|
      # t.action :show, url: {format: :pdf}, image: :print
      t.action :refresh, if: :editable?, method: :post, confirm: :are_you_sure
      t.action :reflect, if: :reflectable?, method: :post, image: 'action', confirm: :are_you_sure
      t.action :edit
      t.action :destroy
      t.column :name, url: true
      t.column :achieved_at
      t.column :reflected_at
      t.column :reflected
      t.column :responsible, url: true
    end

    # Displays the main page with the list of inventories
    def index
      unless ProductNature.stockables.any?
        notify_now(:need_stocks_to_create_inventories)
      end
    end

    def show
      return unless @inventory = find_and_check
      t3e @inventory
      respond_with(@inventory, include: [:responsible, { items: { methods: :unit_name, include: %i[product container] } }])
    end

    list(:items, model: :inventory_items, conditions: { inventory_id: 'params[:id]'.c }, order: :id) do |t|
      # t.column :name, through: :building, url: true
      t.column :product, url: true
      # t.column :serial_number, through: :product
      t.column :expected_population, precision: 3
      t.column :actual_population, precision: 3
      t.column :unit_name, through: :product
    end

    def refresh
      return unless @inventory = find_and_check
      @inventory.refresh!
      redirect_to action: :edit, id: @inventory.id
    end

    def reflect
      return unless @inventory = find_and_check
      if @inventory.reflect
        notify_success(:changes_have_been_reflected)
      else
        notify_error(:changes_have_not_been_reflected)
      end
      redirect_to action: :index
    end
  end
end
