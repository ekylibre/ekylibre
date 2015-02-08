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

class Backend::AnimalGroupsController < Backend::BaseController
  manage_restfully

  respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

  unroll

  list do |t|
    t.column :name, url: true
    t.column :description
    # t.action :show, url: {format: :pdf}, image: :print
    t.action :new,     on: :none
    t.action :edit
    t.action :destroy
  end

  list(:animals, model: :product_memberships, conditions: {group_id: 'params[:id]'.c}, order: :started_at) do |t|
    t.column :member, url: true
    t.column :started_at
    t.column :stopped_at
  end

  list(:places, model: :product_localizations, conditions: {product_id: 'params[:id]'.c}, order: {started_at: :desc}) do |t|
    t.column :container, url: true
    t.column :nature
    t.column :started_at
    t.column :stopped_at
  end

end
