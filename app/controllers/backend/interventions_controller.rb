# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2013 Brice Texier
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
  class InterventionsController < Backend::BaseController
    manage_restfully t3e: { procedure_name: 'RECORD.procedure.human_name'.c }

    respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

    unroll

    # params:
    #   :q Text search
    #   :state State search
    #   :campaign_id
    #   :product_nature_id
    #   :support_id
    def self.list_conditions
      code = ''
      # , productions: [:name]
      code = search_conditions(interventions: [:state, :number], activities: [:name], campaigns: [:name], products: [:name]) + " ||= []\n"
      code << "unless params[:state].blank?\n"
      code << "  c[0] << ' AND #{Intervention.table_name}.state IN (?)'\n"
      code << "  c << params[:state].flatten\n"
      code << "end\n"
      code << "unless params[:procedure_name].blank?\n"
      code << "  c[0] << ' AND #{Intervention.table_name}.procedure_name IN (?)'\n"
      code << "  c << params[:procedure_name]\n"
      code << "end\n"
      code << "c[0] << ' AND ' + params[:nature].join(' AND ') unless params[:nature].blank?\n"

      # Current campaign
      code << "if current_campaign\n"
      code << "  c[0] << \" AND (#{Intervention.table_name}.started_at, #{Intervention.table_name}.stopped_at) OVERLAPS (COALESCE(?, #{Intervention.table_name}.started_at), COALESCE(?, #{Intervention.table_name}.stopped_at))\"\n"
      code << "  c << current_campaign.started_on\n"
      code << "  c << current_campaign.stopped_on\n"
      code << "end\n"

      # Support
      code << "if params[:support_id].to_i > 0\n"
      code << "  c[0] << ' AND production_support_id IN (SELECT id FROM #{ActivityProduction.table_name} WHERE storage_id IN (?))'\n"
      code << "  c << params[:support_id].to_i\n"
      code << "end\n"

      # ActivityProduction || Activity
      code << "if params[:production_id].to_i > 0\n"
      code << "  c[0] << ' AND #{Intervention.table_name}.id IN (SELECT intervention_id FROM intervention_casts WHERE type = \\'InterventionTarget\\' AND product_id IN (SELECT target_id FROM target_distributions WHERE activity_production_id = ?))'\n"
      code << "  c << params[:production_id].to_i\n"
      code << "elsif params[:activity_id].to_i > 0\n"
      code << "  c[0] << ' AND #{Intervention.table_name}.id IN (SELECT intervention_id FROM intervention_casts WHERE type = \\'InterventionTarget\\' AND product_id IN (SELECT target_id FROM target_distributions WHERE activity_id = ?))'\n"
      code << "  c << params[:activity_id].to_i\n"
      code << "end\n"
      code << "c\n "
      code.c
    end

    # INDEX
    # @TODO conditions: list_conditions, joins: [:production, :activity, :campaign, :support]

    # conditions: list_conditions,
    list(conditions: list_conditions, order: { started_at: :desc }, line_class: :status) do |t|
      t.action :run,  if: :runnable?, method: :post, confirm: true
      t.action :edit, if: :updateable?
      t.action :destroy, if: :destroyable?
      t.column :name, sort: :procedure_name, url: true
      # t.column :production, url: true, hidden: true
      # t.column :campaign, url: true
      # t.column :activity, url: true, hidden: true
      t.column :state, hidden: true
      t.column :started_at
      t.column :duration
      t.column :stopped_at, hidden: true
      t.status
      t.column :issue, url: true
      t.column :casting, hidden: true
    end

    # SHOW

    list(:casts, model: :intervention_casts, conditions: { intervention_id: 'params[:id]'.c }, order: { created_at: :desc }) do |t|
      t.column :name, sort: :parameter_name
      t.column :product, url: true
      t.column :human_roles, sort: :roles, label: :roles
      t.column :population
      t.column :unit_name, through: :variant
      t.column :shape, hidden: true
      t.column :variant, url: true
    end

    # Show one intervention with params_id
    def show
      return unless @intervention = find_and_check
      t3e @intervention, procedure_name: @intervention.name
      if params[:mode] == 'spraying'
        render 'spraying'
        return
      end
      respond_with(@intervention, methods: [:cost, :earn, :status, :name, :duration],
                                  include: [{ casts: { methods: [:variable_name, :default_name], include: { product: { methods: [:picture_path, :nature_name, :unit_name] } } } }, { storage: {} }, :recommender, :prescription],
                                  procs: proc { |options| options[:builder].tag!(:url, backend_intervention_url(@intervention)) }
                  )
    end

    def run
      return unless intervention = find_and_check
      intervention.run!({}, params[:parameters])
      redirect_to backend_intervention_url(intervention)
    end

    # Computes reverberation of a updated value in an intervention input context
    # Converts handlers and updates others things in cascade
    def compute
      unless procedure = Procedo[params[:procedure]]
        head :not_found
        return
      end
      begin
        updates = procedure.impact(params[:casting], params[:global], params[:updater])
        respond_to do |format|
          format.xml  { render xml: updates.to_xml }
          format.json { render json: updates.to_json }
        end
      rescue Procedo::Error => e
        respond_to do |format|
          format.xml  { render xml:  { errors: e.message }, status: 500 }
          format.json { render json: { errors: e.message }, status: 500 }
        end
      end
    end
  end
end
