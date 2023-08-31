# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2015 Brice Texier, David Joulin
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
  class ProjectTasksController < Backend::BaseController
    manage_restfully

    unroll :name, project: :name

    # params:
    #   :q Text search
    #   :s State search
    #   :period Two Dates with _ separator
    #   :variant_id
    def self.list_conditions
      code = ''
      code = search_conditions(project_tasks: %i[name comment]) + " ||= []\n"
      code << "  if params[:project_id].to_i > 0\n"
      code << "    c[0] << \" AND \#{Project.table_name}.id = ?\"\n"
      code << "    c << params[:project_id].to_i\n"
      code << "  end\n"
      code << "  if params[:team_id].to_i > 0\n"
      code << "    c[0] << \" AND \#{Team.table_name}.id = ?\"\n"
      code << "    c << params[:team_id].to_i\n"
      code << "  end\n"
      code << "  if params[:responsible_id].to_i > 0\n"
      code << "    c[0] << \" AND \#{User.table_name}.id = ?\"\n"
      code << "    c << params[:responsible_id].to_i\n"
      code << "  end\n"
      code << "c\n"
      code.c
    end

    list(conditions: list_conditions, joins: %i[project team]) do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.column :work_number
      t.column :name, url: true
      t.column :responsible, url: true
      t.column :project, url: true
      t.column :started_on
      t.column :stopped_on
      t.column :forecast_duration # , on_select: :sum
      t.column :forecast_duration_unit
      t.column :real_duration
      t.column :billing_method, hidden: true
      # t.column :sale_contract_item, index: true, hidden: true
    end

    list :task_logs, model: :worker_time_logs, conditions: { project_task_id: 'params[:id]'.c } do |t|
      t.column :worker, url: true
      t.column :started_at, datatype: :datetime
      t.column :stopped_at, datatype: :datetime
      t.column :description
      t.column :human_duration, on_select: :sum, value_method: 'duration.in(:second).in(:hour)', datatype: :decimal, class: 'center-align'
      t.column :travel_expense, hidden: true
      t.column :travel_expense_details, hidden: true
    end
  end
end
