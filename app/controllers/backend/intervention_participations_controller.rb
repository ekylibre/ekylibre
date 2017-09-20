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

    def index
      @worked_on = if params[:worked_on].blank?
                     first_participation = current_user.intervention_participations.unprompted.order(created_at: :desc).first
                     first_participation.present? ? first_participation.created_at : Time.zone.today
                   else
                     params[:worked_on].to_date
                   end
    end

    # Creates an intervention from intervention participation and redirects to an edit form for
    # the newly created intervention.
    def convert
      return unless intervention_participation = find_and_check
      begin
        if intervention = intervention_participation.convert!(params.slice(:procedure_name, :working_width))
          redirect_to edit_backend_intervention_path(intervention)
        elsif current_user.intervention_participations.unprompted.any?
          redirect_to backend_intervention_participations_path(worked_on: params[:worked_on])
        else
          redirect_to backend_interventions_path
        end
      rescue StandardError => e
        notify_error(e.message)
        redirect_to backend_intervention_participations_path(worked_on: params[:worked_on])
      end
    end

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
               calculate_working_periods: calculate_working_periods
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

    def calculate_working_periods
      participations = form_participations
      tool = intervention_tool
      auto_calcul_mode = params[:auto_calcul_mode]

      return [] if !auto_calcul_mode.nil? &&
                   auto_calcul_mode.to_sym == :false ||
                   participations.blank? || tool.nil?

      working_periods = []
      working_duration_params = { intervention: @intervention,
                                  participations: participations,
                                  product: @participation.product }

      natures = %i[travel intervention] if tool.try(:tractor?)
      natures = %i[intervention] unless tool.try(:tractor?)

      natures.each do |nature|
        duration = InterventionWorkingTimeDurationCalculationService
                   .new(**working_duration_params)
                   .perform(nature: nature, modal: true)

        stopped_at = intervention_started_at + (duration * 60 * 60)

        working_periods << InterventionWorkingPeriod
                           .new(nature: nature,
                                started_at: intervention_started_at,
                                stopped_at: stopped_at)
      end

      working_periods
    end
  end
end
