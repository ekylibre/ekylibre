# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2012-2013 David Joulin, Brice Texier
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
  class PlantsController < Backend::MattersController
    include InspectionViewable

    def self.list_conditions
      code = ''
      code = search_conditions(products: %i[name work_number]) + " ||= []\n"
      code << "if params[:born_at].present? && params[:born_at].to_s != 'all'\n"
      code << " c[0] << ' AND #{Plant.table_name}.born_at::DATE BETWEEN ? AND ?'\n"
      code << " if params[:born_at].to_s == 'interval'\n"
      code << "   c << params[:born_at_started_on]\n"
      code << "   c << params[:born_at_stopped_on]\n"
      code << " else\n"
      code << "   interval = params[:born_at].to_s.split('_')\n"
      code << "   c << interval.first\n"
      code << "   c << interval.second\n"
      code << " end\n"
      code << "end\n"

      code << "if params[:dead_at].present? && params[:dead_at].to_s != 'all'\n"
      code << " c[0] << ' AND #{Plant.table_name}.dead_at::DATE BETWEEN ? AND ?'\n"
      code << " if params[:dead_at].to_s == 'interval'\n"
      code << "   c << params[:dead_at_started_on]\n"
      code << "   c << params[:dead_at_stopped_on]\n"
      code << " else\n"
      code << "   interval = params[:dead_at].to_s.split('_')\n"
      code << "   c << interval.first\n"
      code << "   c << interval.second\n"
      code << " end\n"
      code << "end\n"

      code << "if params[:variety].present?\n"
      code << " c[0] << ' AND #{Plant.table_name}.variety = ?'\n"
      code << " c << params[:variety]\n"
      code << "end\n"
      code << "if params[:area].present?\n"
      code << " interval = params[:area].split(',')\n"
      code << " c[0] << ' AND (SELECT (ST_Area(ST_Transform(ST_GeomFromEWKB(#{Plant.table_name}.initial_shape),2154))) BETWEEN ? AND ?)'\n"
      code << " c << interval.first.to_i * 10_000\n"
      code << " c << interval.last.to_i * 10_000\n"
      code << "end\n"
      code << "c\n "
      code.c
    end

    list(conditions: list_conditions) do |t|
      t.action :destroy, if: :destroyable?
      t.column :name, url: true
      t.column :work_number
      t.column :variety
      t.column :work_name, through: :container, url: true
      t.column :net_surface_area, datatype: :measure
      t.status
      t.column :born_at
      t.column :dead_at
    end

    list :plant_countings, conditions: { plant_id: 'params[:id]'.c } do |t|
      t.column :number, url: true
      t.status label: :state
      t.column :read_at, label: :date
    end

    def show
      return unless plant = find_and_check
      harvest_advisor = ::Interventions::Phytosanitary::PhytoHarvestAdvisor.new
      @harvest_possible = harvest_advisor.harvest_possible?(plant, Time.zone.now)
      @reentry_possible = harvest_advisor.reentry_possible?(plant, Time.zone.now)
      super
    end

  end
end
