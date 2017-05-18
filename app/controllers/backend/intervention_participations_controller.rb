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
    manage_restfully only: %i[create update destroy]

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

    def create
      byebug 
      
      # participation = InterventionParticipation.find_or_initialize_by(
      #   product_id: permitted_params[:product_id],
      #   intervention_id: permitted_params[:intervention_id]
      # )
      #
      # permitted_params[:working_periods_attributes].values.each do |working_period_params|
      #   working_period = participation.working_periods.find(working_period_params[:id])
      #   working_period.started_at = Time.strptime(working_period_params[:started_at], '%d/%m/%Y %H:%M:%S')
      #   working_period.stopped_at = Time.strptime(working_period_params[:stopped_at], '%d/%m/%Y %H:%M:%S')
      #   working_period.save
      # end
      #
      # participation.save
    end

    def participations_modal
      participation = InterventionParticipation.find_or_initialize_by(
        product_id: params[:product_id],
        intervention_id: params[:intervention_id]
      )

      render partial: 'backend/intervention_participations/participations_modal', locals: { participation: participation }
    end

    private

    def permitted_params
      params[:intervention_participation].permit(:intervention_id, :product_id, working_periods_attributes: %i[id hours minutes started_at stopped_at])
    end
  end
end
