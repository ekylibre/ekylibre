module Backend
  module Cells
    class HistoricalWeatherCellsController < Backend::Cells::WeatherCellsBaseController
      def show
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

        if params[:period].present?
          period = params[:period].to_sym
        else
          period = :weekly
        end

        response = historical_weather_data(@campaign, started_at, stopped_at)
        if response[:data].present? && response[:error].nil?
          @historical_forecast = build_historical_forecast(response[:data], period)
          @error = nil
        elsif response[:error].present?
          @historical_forecast = nil
          @error = response[:error]
        else
          @historical_forecast = nil
          @error = :error.tl
        end
      end
    end
  end
end
