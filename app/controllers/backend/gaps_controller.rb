# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2013 Brice Texier, David Joulin
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
  class GapsController < Backend::BaseController
    manage_restfully only: %i[index show destroy], subclass_inheritance: true

    list do |t|
      t.action :destroy
      t.column :number, url: true
      t.column :entity, url: true
      t.column :direction
      t.column :pretax_amount, currency: true
      t.column :amount, currency: true
      t.column :printed_at
    end

    list(:items, model: :gap_items, conditions: { gap_id: 'params[:id]'.c }) do |t|
      t.column :tax, url: true
      t.column :pretax_amount, currency: true
      t.column :amount, currency: true
    end
  end
end
