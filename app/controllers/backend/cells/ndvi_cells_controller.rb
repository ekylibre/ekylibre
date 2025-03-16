module Backend
  module Cells
    class NdviCellsController < Backend::Cells::BaseController

      def show
        if params[:cultivable_zone_id].present?
          @cultivable_zone = CultivableZone.find(params[:cultivable_zone_id])
        end

        @campaign = if params[:campaign].present? && params[:campaign].is_a?(Campaign)
                      params[:campaign]
                    elsif params[:campaign_id].present? && params[:campaign_id].is_a?(Integer)
                      Campaign.find(params[:campaign_id])
                    else
                      current_campaign
                    end

        if params[:started_at].present?
          started_at = params[:started_at].to_time
        else
          started_at = Date.new(@campaign.harvest_year, 1, 1)
        end

        if params[:stopped_at].present?
          stopped_at = params[:stopped_at].to_time
        else
          stopped_at = Date.new(@campaign.harvest_year, 12, 31)
        end
        # build dataset
        dataset = Analysis.where(cultivable_zone: @cultivable_zone).with_indicator('minimal_ndvi_index').between(started_at, stopped_at).reorder(:sampled_at)
        if dataset.any?
          @dataset = dataset
        else
          @error = :missing_weather_public_data_in_lexicon.tl
        end
      end

    end
  end
end
