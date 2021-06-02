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
  class EquipmentsController < Backend::MattersController
    # params:
    #   :q Text search
    #   :s State search
    #   :period Two Dates with _ separator
    #   :variant_id
    #   :activity_id
    def self.equipments_conditions
      code = ''
      code = search_conditions(products: %i[name work_number number description uuid],
                               product_nature_variants: [:name]) + " ||= []\n"
      code << "  if params[:variant_id].to_i > 0\n"
      code << "    c[0] << \" AND \#{ProductNatureVariant.table_name}.id = ?\"\n"
      code << "    c << params[:variant_id].to_i\n"
      code << "  end\n"

      # filter by activity_id
      code << "  if params[:activity_id].to_i > 0\n"
      code << "    c[0] << \" AND \#{Equipment.table_name}.id IN (SELECT target_id FROM target_distributions WHERE activity_id = ?)\"\n"
      code << "    c << params[:activity_id].to_i\n"
      code << "  end\n"

      code << "c\n"
      code.c
    end

    list(conditions: equipments_conditions, joins: :variants) do |t|
      t.action :edit
      t.action :destroy
      t.column :work_number, url: true
      t.column :name, url: true
      t.column :born_at
      t.status
      t.column :state, hidden: true
      t.column :container, url: true
      t.column :isacompta_analytic_code, hidden: AnalyticSegment.where(name: 'equipments').none?
    end

    list(:links, model: :product_link, conditions: { product_id: 'params[:id]'.c }) do |t|
      t.column :nature
      t.column :linked_id, url: { controller: 'backend/equipments', id: 'RECORD.linked_id'.c }, label_method: :linked_name
    end

    list(:interventions_on_field, model: :intervention_parameters, joins: :intervention, conditions: [
      "(interventions.nature = ?
        AND interventions.procedure_name != ?
        AND intervention_parameters.product_id = ?
       )
      OR
       (interventions.nature = ?
        AND interventions.procedure_name = ?
        AND intervention_parameters.product_id = ?
        AND intervention_parameters.type = ?
      )",
      'record', Procedo::Procedure.find(:equipment_maintenance).name, 'params[:id]'.c,
      'record', Procedo::Procedure.find(:equipment_maintenance).name, 'params[:id]'.c, 'InterventionTool'
    ]) do |t|
      t.column :intervention, url: true
      t.column :reference, label_method: :name, sort: :reference_name
      t.column :started_at, through: :intervention, datatype: :datetime
      t.column :stopped_at, through: :intervention, datatype: :datetime, hidden: true
      t.column :human_activities_names, through: :intervention
      t.column :actions, label_method: :human_actions_names, through: :intervention
      t.column :human_working_duration, through: :intervention
      t.column :human_working_zone_area, through: :intervention
    end

    list(:equipment_maintenance_interventions, model: :intervention_parameters, joins: :intervention, conditions: [
      "interventions.nature = ?
       AND interventions.procedure_name = ?
       AND intervention_parameters.product_id = ?
       AND intervention_parameters.type = ?",
      'record', Procedo::Procedure.find(:equipment_maintenance).name, 'params[:id]'.c, 'InterventionTarget'
    ]) do |t|
      t.column :intervention, url: true
      t.column :reference, label_method: :name, sort: :reference_name
      t.column :started_at, through: :intervention, datatype: :datetime
      t.column :stopped_at, through: :intervention, datatype: :datetime, hidden: true
      t.column :human_activities_names, through: :intervention
      t.column :actions, label_method: :human_actions_names, through: :intervention
      t.column :human_working_duration, through: :intervention
      t.column :human_working_zone_area, through: :intervention
    end

    def index
      missing_code_count = Equipment.where("isacompta_analytic_code IS NULL OR isacompta_analytic_code = ''").count
      segment = AnalyticSegment.find_by(name: 'equipments')
      if segment.presence && missing_code_count > 0
        notify_warning :fill_analytic_codes_of_your_activities.tl(segment: segment.name.text.downcase, missing_code_count: missing_code_count)
      end
      respond_to do |format|
        format.html
        format.xml  { render xml:  resource_model.all }
        format.json { render json: resource_model.all }
      end
    end
  end
end
