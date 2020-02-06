module Api
  module V1
    # Interventions API permits to access interventions
    class InterventionsController < Api::V1::BaseController
      def index
        nature = params[:nature] || 'record'
        @interventions = Intervention
        unless %w[record request].include? nature
          head :unprocessable_entity
          return
        end

        page = (params[:page] || 1).to_i
        unless page > 0
          head :unprocessable_entity
          return
        end
        per_page = (params[:per_page] || 30).to_i
        unless (30..100).cover?(per_page)
          head :unprocessable_entity
          return
        end
        if params[:contact_email]
          entity = Entity.with_email(params[:contact_email])
          unless entity
            head :unprocessable_entity
            return
          end
          @interventions = @interventions.with_doers(entity.worker)
        elsif params[:user_email]
          user = User.find_by(email: params[:user_email])
          unless user
            head :unprocessable_entity
            return
          end
          @interventions = @interventions.with_doers(user.worker)
        end

        return render json: { message: :no_worker_associated_with_user_account.tn }, status: :precondition_required if user && user.worker.nil?

        if nature == 'request'
          @interventions = @interventions
                           .joins('LEFT JOIN interventions record_interventions_interventions ON record_interventions_interventions.request_intervention_id = interventions.id')
                           .joins('LEFT JOIN intervention_participations ON record_interventions_interventions.id = intervention_participations.intervention_id')
                           .joins('LEFT JOIN products AS workers_included ON intervention_participations.product_id = workers_included.id')
                           .where('workers_included.id IS NULL OR workers_included.id != ? OR (workers_included.id = ? AND intervention_participations.state = \'in_progress\')', user.worker.id, user.worker.id)
          if params[:with_interventions]
            if params[:with_interventions] == 'true'
              @interventions = @interventions.where(id: Intervention.select(:request_intervention_id))
            elsif params[:with_interventions] == 'false'
              @interventions = @interventions.where.not(id: Intervention.select(:request_intervention_id))
            else
              head :unprocessable_entity
              return
            end
          end
        end
        @interventions = @interventions.where(nature: nature).where.not(state: :rejected).page(page).per(per_page).order(:id)
      end

      def create
        intervention = Intervention.new(permitted_params)
        if intervention.save
          render json: { id: intervention.id }, status: :created
        else
          render json: intervention.errors, status: :unprocessable_entity
        end
      end

      protected

      def permitted_params
        super.permit(:procedure_name, :description, working_periods_attributes: %i[started_at stopped_at])
      end
    end
  end
end
