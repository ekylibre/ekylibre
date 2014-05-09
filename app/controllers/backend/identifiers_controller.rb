# encoding: utf-8
# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2013 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::IdentifiersController < BackendController
  manage_restfully t3e: {name: :nature}

  unroll

  list conditions: {net_service_id: nil} do |t|
    t.column :net_service, label_method: :name, url: true
    t.column :nature
    t.column :value
    t.action :edit
    t.action :destroy
  end
end
