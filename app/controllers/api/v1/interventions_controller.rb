module Api
  module V1
    # Interventions API permits to access interventions
    class InterventionsController < Api::V1::BaseController
      def index
        nature = params[:nature] || 'record'
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
        @interventions = Intervention.where(nature: nature).page(page).per(per_page).order(:id)
      end
    end
  end
end
