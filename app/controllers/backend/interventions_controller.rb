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

require_dependency 'procedo'

module Backend
  class InterventionsController < Backend::BaseController
    manage_restfully t3e: { procedure_name: '(RECORD.procedure ? RECORD.procedure.human_name : nil)'.c },
                     continue: %i[nature procedure_name]

    respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

    unroll

    # params:
    #   :q Text search
    #   :cultivable_zone_id
    #   :campaign_id
    #   :product_nature_id
    #   :support_id
    def self.list_conditions
      conn = Intervention.connection
      # , productions: [:name], campaigns: [:name], activities: [:name], products: [:name]
      expressions = []
      expressions << 'CASE ' + Procedo.selection.map { |l, n| "WHEN procedure_name = #{conn.quote(n)} THEN #{conn.quote(l)}" }.join(' ') + " ELSE '' END"
      code = search_conditions({ interventions: %i[state procedure_name number] }, expressions: expressions) + " ||= []\n"
      code << "unless params[:state].blank?\n"
      code << "  c[0] << ' AND #{Intervention.table_name}.state IN (?)'\n"
      code << "  c << params[:state]\n"
      code << "end\n"

      code << "unless params[:nature].blank?\n"
      code << "  c[0] << ' AND #{Intervention.table_name}.nature IN (?)'\n"
      code << "  c << params[:nature]\n"
      code << "end\n"

      code << "c[0] << ' AND ((#{Intervention.table_name}.nature = ? AND #{Intervention.table_name}.state != ? AND (#{Intervention.table_name}.request_intervention_id IS NULL OR #{Intervention.table_name}.request_intervention_id NOT IN (SELECT id from #{Intervention.table_name})) OR #{Intervention.table_name}.nature = ?))'\n"
      code << "c << 'request'\n"
      code << "c << '#{Intervention.state.rejected}'\n"
      code << "c << 'record'\n"

      code << "unless params[:procedure_name].blank?\n"
      code << "  c[0] << ' AND #{Intervention.table_name}.procedure_name IN (?)'\n"
      code << "  c << params[:procedure_name]\n"
      code << "end\n"

      # select the interventions according to the user current period
      code << "unless current_period_interval.blank? && current_period.blank?\n"

      code << " if current_period_interval.to_sym == :day\n"
      code << "   c[0] << ' AND EXTRACT(DAY FROM #{Intervention.table_name}.started_at) = ? AND EXTRACT(MONTH FROM #{Intervention.table_name}.started_at) = ? AND EXTRACT(YEAR FROM #{Intervention.table_name}.started_at) = ?'\n"
      code << "   c << current_period.to_date.day\n"
      code << "   c << current_period.to_date.month\n"
      code << "   c << current_period.to_date.year\n"

      code << " elsif current_period_interval.to_sym == :week\n"
      code << "   c[0] << ' AND #{Intervention.table_name}.started_at >= ? AND #{Intervention.table_name}.stopped_at <= ?'\n"
      code << "   c << current_period.to_date.at_beginning_of_week.to_time.beginning_of_day\n"
      code << "   c << current_period.to_date.at_end_of_week.to_time.end_of_day\n"

      code << " elsif current_period_interval.to_sym == :month\n"
      code << "   c[0] << ' AND EXTRACT(MONTH FROM #{Intervention.table_name}.started_at) = ? AND EXTRACT(YEAR FROM #{Intervention.table_name}.started_at) = ?'\n"
      code << "   c << current_period.to_date.month\n"
      code << "   c << current_period.to_date.year\n"

      code << " elsif current_period_interval.to_sym == :year\n"
      code << "   c[0] << ' AND EXTRACT(YEAR FROM #{Intervention.table_name}.started_at) = ?'\n"
      code << "   c << current_period.to_date.year\n"
      code << " end\n"

      # Cultivable zones
      code << "  if params[:cultivable_zone_id].to_i > 0\n"
      code << "    c[0] << ' AND #{Intervention.table_name}.id IN (SELECT intervention_id FROM activity_productions_interventions INNER JOIN #{ActivityProduction.table_name} ON #{ActivityProduction.table_name}.id = activity_production_id INNER JOIN #{CultivableZone.table_name} ON #{CultivableZone.table_name}.id = #{ActivityProduction.table_name}.cultivable_zone_id WHERE #{CultivableZone.table_name}.id = ' + params[:cultivable_zone_id] + ')'\n"
      code << "    c \n"
      code << "  end\n"

      # Current campaign
      code << "  if current_campaign\n"
      code << "    c[0] << \" AND EXTRACT(YEAR FROM #{Intervention.table_name}.started_at) = ?\"\n"
      code << "    c << current_campaign.harvest_year\n"
      code << "  end\n"
      code << "end\n"

      # Support
      code << "if params[:product_id].to_i > 0\n"
      code << "  c[0] << ' AND #{Intervention.table_name}.id IN (SELECT intervention_id FROM intervention_parameters WHERE type = \\'InterventionTarget\\' AND product_id IN (?))'\n"
      code << "  c << params[:product_id].to_i\n"
      code << "end\n"

      # Label
      code << "if params[:label_id].to_i > 0\n"
      code << "  c[0] << ' AND #{Intervention.table_name}.id IN (SELECT intervention_id FROM intervention_labellings WHERE label_id IN (?))'\n"
      code << "  c << params[:label_id].to_i\n"
      code << "end\n"

      # ActivityProduction || Activity
      code << "if params[:production_id].to_i > 0\n"
      code << "  c[0] << ' AND #{Intervention.table_name}.id IN (SELECT intervention_id FROM intervention_parameters WHERE type = \\'InterventionTarget\\' AND product_id IN (SELECT target_id FROM target_distributions WHERE activity_production_id = ?))'\n"
      code << "  c << params[:production_id].to_i\n"
      code << "elsif params[:activity_id].to_i > 0\n"
      code << "  c[0] << ' AND #{Intervention.table_name}.id IN (SELECT intervention_id FROM intervention_parameters WHERE type = \\'InterventionTarget\\' AND product_id IN (SELECT target_id FROM target_distributions WHERE activity_id = ?))'\n"
      code << "  c << params[:activity_id].to_i\n"
      code << "end\n"
      code << "c\n "
      code.c
    end

    # INDEX
    # @TODO conditions: list_conditions, joins: [:production, :activity, :campaign, :support]

    # conditions: list_conditions,
    list(conditions: list_conditions, order: { started_at: :desc }, line_class: :status) do |t|
      t.action :purchase, on: :both, method: :post
      t.action :sell,     on: :both, method: :post
      t.action :edit, if: :updateable?
      t.action :destroy, if: :destroyable?
      t.column :name, sort: :procedure_name, url: true
      t.column :procedure_name, hidden: true
      # t.column :production, url: true, hidden: true
      # t.column :campaign, url: true
      t.column :human_activities_names
      t.column :started_at
      t.column :stopped_at, hidden: true
      t.column :human_working_duration, on_select: :sum, value_method: 'working_duration.in(:second).in(:hour)', datatype: :decimal
      t.status
      t.column :human_target_names
      t.column :human_working_zone_area, on_select: :sum, datatype: :decimal
      t.column :total_cost, label_method: :human_total_cost, currency: true, on_select: :sum, datatype: :decimal
      t.column :nature
      t.column :issue, url: true
      t.column :trouble_encountered, hidden: true
      # t.column :casting
      # t.column :human_target_names, hidden: true
    end

    # SHOW

    list(:product_parameters, model: :intervention_product_parameters, conditions: { intervention_id: 'params[:id]'.c }, order: { created_at: :desc }) do |t|
      t.column :name, sort: :reference_name
      t.column :product, url: true
      # t.column :human_roles, sort: :roles, label: :roles
      t.column :quantity_population
      t.column :unit_name, through: :variant
      # t.column :working_zone, hidden: true
      t.column :variant, url: true
    end

    list(:record_interventions, model: :interventions, conditions: { request_intervention_id: 'params[:id]'.c }, order: 'interventions.started_at DESC') do |t|
      # t.column :roles, hidden: true
      t.column :name, sort: :reference_name
      t.column :started_at, datatype: :datetime
      t.column :stopped_at, datatype: :datetime
      t.column :human_activities_names, through: :intervention
      t.column :human_working_duration, through: :intervention
      t.column :human_working_zone_area, through: :intervention
    end

    # Show one intervention with params_id
    def show
      return unless @intervention = find_and_check
      t3e @intervention, procedure_name: @intervention.procedure.human_name
      respond_with(@intervention, methods: %i[cost earn status name duration human_working_zone_area human_actions_names],
                                  include: [
                                    { leaves_parameters: {
                                      methods: %i[reference_name default_name working_zone_svg human_quantity human_working_zone_area],
                                      include: {
                                        product: {
                                          methods: %i[picture_path nature_name unit_name]
                                        }
                                      }
                                    } }, {
                                      prescription: {
                                        include: %i[prescriptor attachments]
                                      }
                                    }
                                  ],
                                  procs: proc { |options| options[:builder].tag!(:url, backend_intervention_url(@intervention)) })
    end

    def new
      options = {}
      %i[actions custom_fields description event_id issue_id
         nature number prescription_id procedure_name
         request_intervention_id started_at state
         stopped_at trouble_description trouble_encountered
         whole_duration working_duration].each do |param|
        options[param] = params[param]
      end

      # , :doers, :inputs, :outputs, :tools
      %i[group_parameters targets].each do |param|
        next unless params.include? :intervention
        options[:"#{param}_attributes"] = permitted_params["#{param}_attributes"] || []

        next unless options[:targets_attributes]

        next if permitted_params.include? :working_periods
        targets = if options[:targets_attributes].is_a? Array
                    options[:targets_attributes].collect { |k, _| k[:product_id] }
                  else
                    options[:targets_attributes].collect { |_, v| v[:product_id] }
                  end
        availables = Product.where(id: targets).at(Time.zone.now - 1.hour).collect(&:id)

        options[:targets_attributes].select! do |k, v|
          obj = k.is_a?(Hash) ? k : v
          obj.include?(:product_id) && availables.include?(obj[:product_id].to_i)
        end
      end

      # consume preference and erase
      keeper_pref = params[:keeper_id]
      selection = keeper_pref && current_user.preferences.get(keeper_pref)
      if selection && (selected = selection.value).present?
        target_name = params[:reference_name]
        selected = selected.split(',')

        attributes = selected.map.with_index do |selected_target, index|
          target_attributes = {
            targets_attributes: {
              -index => { reference_name: target_name }
            }
          }

          new_attributes = {}

          %i[new_group new_container].each do |parameter_name|
            param_value = params[parameter_name]
            if param_value && (new_id = Product.find_by(id: param_value).id)
              new_attributes[-index][:"#{parameter_name}_id"] = new_id
            end
          end

          selected_product = Product.find_by(id: selected_target)
          new_attributes[:product_id] = selected_target if selected_product

          target_attributes[:targets_attributes][-index].merge!(new_attributes)

          procedure = Procedo::Procedure.find(params[:procedure_name])
          element = procedure.find_element_with_name(target_name)

          next target_attributes if element.cardinality != 1

          parents = element.ancestors
          first_duplicatable_parent = parents.index { |p| p.position != 1 }
          nonduplicatable_parents = parents[0...first_duplicatable_parent]

          if nonduplicatable_parents == parents
            raise "Can't select multiple targets for intervention #{params[:procedure_name]}"
          end

          nonduplicatable_parents.reduce(target_attributes) do |attrs, parent|
            {
              groups_attributes:
              {
                -index => { reference_name: parent.name }.merge(attrs)
              }
            }
          end
        end.compact
      end
      if attributes.present?
        attributes = attributes.reduce(&:deep_merge)

        attributes_root = attributes.keys.first
        parameter_type = attributes_root.to_s.gsub('s_attributes', '')
        suffix = parameter_type.to_sym == :group ? :_parameters : :s
        targets = { "#{parameter_type}#{suffix}_attributes": attributes[attributes_root] }

        @intervention = Intervention.new(options.merge(targets))

        from_request = Intervention.find_by(id: params[:request_intervention_id])
        @intervention = from_request.initialize_record if from_request
      else
        @intervention = Intervention.new(options)
      end

      render(locals: { cancel_url: { action: :index }, with_continue: true })
    end

    def create
      unless permitted_params[:participations_attributes].nil?
        participations = permitted_params[:participations_attributes]

        participations.each_pair do |key, value|
          participations[key] = JSON.parse(value)
        end

        permitted_params[:participations_attributes] = participations
      end

      @intervention = Intervention.new(permitted_params)

      url = if params[:create_and_continue]
              { action: :new, continue: true }
            else
              params[:redirect] || { action: :show, id: 'id'.c }
            end

      return if save_and_redirect(@intervention, url: url, notify: :record_x_created, identifier: :number)
      render(locals: { cancel_url: { action: :index }, with_continue: true })
    end

    def update
      @intervention = find_and_check

      unless permitted_params[:participations_attributes].nil?
        participations = permitted_params[:participations_attributes]
        participations.each_pair do |key, value|
          participations[key] = JSON.parse(value)
        end

        permitted_params[:participations_attributes] = participations

        delete_working_periods(participations)
      end

      if @intervention.update_attributes(permitted_params)
        redirect_to action: :show
      else
        render :edit
      end
    end

    def sell
      interventions = params[:id].split(',')
      return unless interventions
      if interventions
        redirect_to new_backend_sale_path(intervention_ids: interventions)
      else
        redirect_to action: :index
      end
    end

    def purchase
      interventions = params[:id].split(',')
      if interventions
        redirect_to new_backend_purchase_path(intervention_ids: interventions)
      else
        redirect_to action: :index
      end
    end

    # Computes impacts of a updated value in an intervention input context
    def compute
      unless params[:intervention]
        head(:unprocessable_entity)
        return
      end
      intervention_params = params[:intervention].deep_symbolize_keys
      procedure = Procedo.find(intervention_params[:procedure_name])
      unless procedure
        head(:not_found)
        return
      end
      intervention = Procedo::Engine.new_intervention(intervention_params)
      begin
        intervention.impact_with!(params[:updater])
        updater_id = 'intervention_' + params[:updater].gsub('[', '_attributes_').tr(']', '_')
        # raise intervention.to_hash.inspect
        respond_to do |format|
          # format.xml  { render xml: intervention.to_xml }
          format.json { render json: { updater_id: updater_id, intervention: intervention, handlers: intervention.handlers_states, procedure_states: intervention.procedure_states }.to_json }
        end
      rescue Procedo::Error => e
        respond_to do |format|
          # format.xml  { render xml:  { errors: e.message }, status: 500 }
          format.json { render json: { errors: e.message }, status: 500 }
        end
      end
    end

    def modal
      if params[:intervention_id]
        @intervention = Intervention.find(params[:intervention_id])
        render partial: 'backend/interventions/details_modal', locals: { intervention: @intervention }
      end

      if params[:interventions_ids]
        @interventions = Intervention.find(params[:interventions_ids].split(','))

        if params[:modal_type] == 'delete'
          render partial: 'backend/interventions/delete_modal', locals: { interventions: @interventions }
        else
          render partial: 'backend/interventions/change_state_modal', locals: { interventions: @interventions }
        end
      end
    end

    def change_state
      unless state_change_permitted_params
        head :unprocessable_entity
        return
      end

      interventions_ids = JSON.parse(state_change_permitted_params[:interventions_ids]).to_a
      new_state = state_change_permitted_params[:state].to_sym

      @interventions = Intervention.find(interventions_ids)

      Intervention.transaction do
        @interventions.each do |intervention|
          if intervention.nature == :record && new_state == :rejected

            unless intervention.request_intervention_id.nil?
              intervention_request = Intervention.find(intervention.request_intervention_id)

              if state_change_permitted_params[:delete_option].to_sym == :delete_request
                intervention_request.destroy!
              else
                intervention_request.parameters = intervention.parameters
                intervention_request.save!
              end
            end

            intervention.destroy!
            next
          end

          if intervention.nature == :request && new_state == :rejected
            intervention.state = new_state

            next unless intervention.valid?
            intervention.save!

            next
          end

          new_intervention = intervention

          if intervention.nature == :request
            new_intervention = intervention.dup
            new_intervention.parameters = intervention.parameters
            new_intervention.request_intervention_id = intervention.id
          end

          new_intervention.state = new_state
          new_intervention.nature = :record

          next unless new_intervention.valid?
          new_intervention.save!
        end
      end

      redirect_to_back
    end

    # FIXME: Not linked directly to interventions
    def change_page
      options = params.require(:interventions_taskboard).permit(:q, :procedure_name, :product_id, :cultivable_zone_id, :period_interval, :period, :page)
      options[:period_interval] ||= current_period_interval
      options[:period] ||= current_period

      @interventions_by_state = {
        requests:  Intervention.with_unroll(options.merge(nature: :request)),
        current:   Intervention.with_unroll(options.merge(nature: :record, state: :in_progress)),
        finished:  Intervention.with_unroll(options.merge(nature: :record, state: :done)),
        validated: Intervention.with_unroll(options.merge(nature: :record, state: :validated))
      }
      respond_to do |format|
        format.js
      end
    end

    private

    def find_interventions
      intervention_ids = params[:id].split(',')
      interventions = intervention_ids.map { |id| Intervention.find_by(id: id) }.compact
      unless interventions.any?
        notify_error :no_interventions_given
        redirect_to(params[:redirect] || { action: :index })
        return nil
      end
      interventions
    end

    def delete_working_periods(form_participations)
      working_periods_ids = form_participations
                            .values
                            .map { |participation| participation['working_periods_attributes'].map { |working_period| working_period['id'] } }
                            .flatten
                            .compact
                            .uniq
                            .map(&:to_i)

      saved_working_periods_ids = @intervention
                                  .participations
                                  .map { |participation| participation.working_periods.map(&:id) }
                                  .flatten

      working_periods_to_destroy = saved_working_periods_ids - working_periods_ids
      InterventionWorkingPeriod.where(id: working_periods_to_destroy).destroy_all

      @intervention.reload
    end

    def state_change_permitted_params
      params.require(:intervention).permit(:interventions_ids, :state, :delete_option)
    end
  end
end
