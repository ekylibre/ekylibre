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
  class WorkerTimeLogsController < Backend::BaseController
    manage_restfully except: :index, stopped_at: 'Time.zone.now'.c, started_at: 'Time.zone.now - 4.hours'.c

    def self.list_conditions
      code = search_conditions(worker_time_logs: %i[description started_at], workers: %i[name]) + " ||= []\n"
      code << "if params[:period].present? && params[:period].to_s != 'all'\n"
      code << "  c[0] << ' AND #{WorkerTimeLog.table_name}.started_at BETWEEN ? AND ?'\n"
      code << "  if params[:period].to_s == 'interval'\n"
      code << "    c << params[:started_on].to_time\n"
      code << "    c << params[:stopped_on].to_time\n"
      code << "  else\n"
      code << "    interval = params[:period].to_s.split('_')\n"
      code << "    c << Date.parse(interval.first).to_time\n"
      code << "    c << Date.parse(interval.second).to_time\n"
      code << "  end\n"
      code << "end\n"
      code << "if params[:worker_id].to_i > 0\n"
      code << "  c[0] += ' AND #{WorkerTimeLog.table_name}.worker_id = ?'\n"
      code << "  c << params[:worker_id]\n"
      code << "end\n"
      code.c
    end

    list(conditions: list_conditions, joins: %i[worker], order: { started_at: :desc }) do |t|
      t.action :edit
      t.action :destroy
      t.column :worker, url: true
      t.column :started_at, datatype: :datetime
      t.column :stopped_at, datatype: :datetime
      t.column :description
      t.column :human_duration, on_select: :sum, value_method: 'duration.in(:second).in(:hour)', datatype: :decimal, class: 'center-align'
    end

    def index
      started_at = (params[:started_on] ? Time.new(*params[:started_on].split('-')) : Time.zone.now)
      @time_logs = WorkerTimeLog.between(started_at.beginning_of_month.beginning_of_week, started_at.end_of_month.end_of_week)
      render partial: 'month' if request.xhr? && params[:started_on]
    end

  end
end
