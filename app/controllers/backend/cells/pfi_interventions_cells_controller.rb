module Backend
  module Cells
    class PfiInterventionsCellsController < Backend::Cells::BaseController
      before_action :find_campaign, only: %i[show compute_pfi_interventions compute_pfi_report]

      def show; end

      def compute_pfi_interventions
        interventions = Intervention.where(nature: 'record').of_nature_using_phytosanitary.of_campaign(@campaign)
        PfiCalculationJob.perform_later(@campaign.id, interventions.pluck(:id), current_user)
      end

      def compute_pfi_report
        activity_ids = Activity.actives.of_campaign(@campaign).pluck(:id)
        PfiReportJob.perform_later(@campaign, activity_ids, current_user)
      end

      private

        def find_campaign
          @campaign = if params[:campaign_id]
                        Campaign.find(params[:campaign_id])
                      elsif current_campaign
                        current_campaign
                      else
                        Campaign.current.last
                      end
        end

    end
  end
end
