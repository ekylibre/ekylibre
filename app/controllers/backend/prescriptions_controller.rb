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
  class PrescriptionsController < Backend::BaseController
    manage_restfully
    manage_restfully_attachments

    unroll

    list do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :reference_number, url: true
      t.column :delivered_at
      t.column :prescriptor, url: true
      # t.column :document, url: true
    end

    # List of interventions with precription_id
    list(:interventions, conditions: { prescription_id: 'params[:id]'.c }, order: { started_at: :desc }) do |t|
      t.column :reference_name, label_method: :name, url: true
      t.column :casting
      t.column :started_at
      t.column :stopped_at, hidden: true
      t.column :state
    end
  end
end
