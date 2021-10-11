# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2014 Sebastien Gauvrit, Brice Texier
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
  class InterventionParticipationsController < Backend::BaseController
    manage_restfully only: %i[update destroy]

    def participations_modal
      @participation = nil

      if params['existing_participation'].present?
        json_participation = JSON.parse(params['existing_participation'])
        @participation = InterventionParticipation.new(json_participation)
      else
        @participation = InterventionParticipation.find_or_initialize_by(
          product_id: params[:product_id],
          intervention_id: params[:intervention_id]
        )
      end

      @intervention = @participation.intervention

      if @intervention.nil? && (params[:intervention_id].nil? || params[:intervention_id].blank?)

        # try to infer new intervention from form
        attrs = Rack::Utils.parse_nested_query(params[:intervention_form])

        if attrs.key?('intervention')
          # Removes participation_attributes as it is not intented to be given to intervention model directly.
          attrs['intervention'].delete('participation_attributes')
          attrs['intervention'].delete('participations_attributes')
          @intervention = Intervention.new(attrs['intervention'])
        end
      end

      auto_calcul_mode = true
      if params[:auto_calcul_mode].present?
        auto_calcul_mode = params[:auto_calcul_mode]
      elsif !@intervention.nil? && !@intervention.new_record?
        auto_calcul_mode = @intervention.auto_calcul_mode
      end

      render partial: 'backend/intervention_participations/participations_modal',
             locals: {
               participation: @participation,
               intervention_started_at: intervention_started_at,
               tool: intervention_tool,
               auto_calcul_mode: auto_calcul_mode.to_b.to_s,
               calculate_working_periods: calculate_working_periods(@intervention, @participation)
             }
    end

    private

      def permitted_params
        params[:intervention_participation].permit(:intervention_id,
                                                   :product_id,
                                                   working_periods_attributes: %i[id started_at stopped_at nature])
      end

      def form_participations
        form_participations = []

        return form_participations if params[:participations].blank?

        params[:participations].each do |form_participation|
          form_participations << InterventionParticipation.new(JSON.parse(form_participation))
        end

        form_participations
      end

      def intervention_tool
        return nil if params[:product_id].nil?

        product = Product.find(params[:product_id])

        return nil unless product.is_a?(Equipment)

        product
      end

      def intervention_started_at
        return Time.parse(params['intervention_started_at']) if params['intervention_started_at'].present?

        Time.now
      end

      def calculate_working_periods(intervention, participation)
        participations = form_participations
        tool = intervention_tool
        auto_calcul_mode = params[:auto_calcul_mode]

        return [] if !auto_calcul_mode.nil? &&
                     auto_calcul_mode.to_sym == :false ||
                     participations.blank? || tool.nil?

        working_duration_params = { intervention: intervention,
                                    participations: participations,
                                    product: participation.product }

        natures = [:intervention, (:travel if tool.try(:tractor?))].compact

        compute_service = InterventionWorkingTimeDurationCalculationService
                     .new(**working_duration_params)
        previous_stopped_at = intervention_started_at

        natures.map do |nature|
          duration = compute_service.perform(nature: nature, modal: true)

          stopped_at = previous_stopped_at + (duration * 60 * 60)

          working_period = InterventionWorkingPeriod
                             .new(nature: nature,
                                  started_at: previous_stopped_at,
                                  stopped_at: stopped_at)

          previous_stopped_at = stopped_at

          working_period
        end
      end
  end
end
