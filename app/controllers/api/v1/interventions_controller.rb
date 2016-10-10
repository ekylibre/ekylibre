module Api
  module V1
    # Interventions API permits to access interventions
    class InterventionsController < Api::V1::BaseController
      def index
        nature = params[:nature] || 'record'
        @interventions = Intervention
        unless %w(record request).include? nature
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
        if nature == 'request'
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
        @interventions = @interventions.where(nature: nature).page(page).per(per_page).order(:id)
      end
    end
  end
end
