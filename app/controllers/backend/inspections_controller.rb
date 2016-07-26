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
  class InspectionsController < Backend::BaseController
    manage_restfully sampled_at: 'Time.zone.now'.c

    unroll

    list do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :activity, url: true
      t.column :product, url: true
      t.column :sampled_at, datatype: :datetime
      # t.column :implanter_rows_number
      # t.column :implanter_working_width
    end

    def set_view_preference
      id = params[:inspection_id]
      id ||= params[:id]
      Inspection.find(id).unit_preference(current_user, params['preference'])
      destination = params['redirect'] if params['redirect']
      destination ||= { action: 'show', id: params[:id] }
      redirect_to destination
    end
  end
end
