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
  class RolesController < Backend::BaseController
    include Pickable

    manage_restfully

    importable_from_lexicon :user_roles

    unroll

    list(order: :name) do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :name, url: true
    end

    list(:users, conditions: { role_id: 'params[:id]'.c }, line_class: "(RECORD.locked ? 'critic' : '')".c, order: :last_name) do |t|
      t.action :locked, actions: { true => { controller: :users, action: :unlock }, false => { controller: :users, action: :lock } }, method: :post, if: 'RECORD.id != current_user.id'.c
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :first_name, url: true
      t.column :last_name, url: true
      t.column :administrator
      t.column :team, url: true
    end
  end
end
