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
  class WorkersController < Backend::ProductsController

    def self.list_conditions
      code = search_conditions(workers: %i[name number work_number description], products: %i[variety]) + " ||= []\n"

      code << "if params[:variant_id].present?\n"
      code << " c[0] << ' AND #{Worker.table_name}.variant_id = ?'\n"
      code << " c << params[:variant_id]\n"
      code << "end\n"
      code << "c\n "
      code.c
    end

    def self.worker_time_logs_conditions
      code = search_conditions(worker_time_logs: %i[worker description]) + " ||= []\n"
      code << "if params[:id].present?\n"
      code << " c[0] << ' AND #{WorkerTimeLog.table_name}.worker_id = ?'\n"
      code << " c << params[:id]\n"
      code << "end\n"

      code << "if params[:current_period].present?\n"
      code << " c[0] << ' AND EXTRACT(YEAR FROM #{WorkerTimeLog.table_name}.started_at) = ?'\n"
      code << " c << params[:current_period].to_date.year\n"
      code << "end\n"
      code << "c\n "
      code.c

    end

    list(conditions: list_conditions, selectable: true) do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :number, url: true
      t.column :work_number
      t.column :name, url: true
      t.column :variant, url: { controller: 'RECORD.variant.class.name.tableize'.c, namespace: :backend }
      t.column :variety
      t.column :container, url: true
      t.column :description
    end

    list(:time_logs, model: :worker_time_logs, conditions: worker_time_logs_conditions, order: { started_at: :asc }) do |t|
      t.action :edit
      t.action :destroy
      t.column :started_at, datatype: :datetime
      t.column :stopped_at, datatype: :datetime
      t.column :project_task
      t.column :description
      t.column :human_duration, on_select: :sum, value_method: 'duration.in(:second).in(:hour)', datatype: :decimal, class: 'center-align'
    end

    list(:catalog_items, conditions: { product_id: 'params[:id]'.c }) do |t|
      t.action :edit, url: { controller: '/backend/catalog_items' }
      t.action :destroy, url: { controller: '/backend/catalog_items' }
      t.column :name, url: { controller: '/backend/catalog_items' }
      t.column :unit
      t.column :amount, url: { controller: '/backend/catalog_items' }, currency: true
      t.column :all_taxes_included
      t.column :catalog, url: { controller: '/backend/catalogs' }
      t.column :started_at
      t.column :stopped_at
    end

    def index
      respond_to do |format|
        format.pdf do
          return unless (template = find_and_check :document_template, params[:template])

          PrinterJob.perform_later('Printers::WorkerRegisterPrinter', template: template, campaign: current_campaign, perform_as: current_user)
          notify_success(:document_in_preparation)
          redirect_to backend_workers_path
        end

        format.html { super }
      end
    end
  end
end
