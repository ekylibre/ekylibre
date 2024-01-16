# frozen_string_literal: true

module FarmProfiles
  class GeneralInformations

    def initialize(harvest_year)
      @campaign = Campaign.of(harvest_year)
      @farm = Entity.of_company
      @farm_default_address = @farm.default_mail_address
      @cap_statement = CapStatement.find_by(campaign: @campaign)
      @started_at = Date.new(@campaign.harvest_year, 1, 1)
      @stopped_at = Date.new(@campaign.harvest_year, 12, 31)
      @station_id = Preference[:weather_public_station]
      @station_name = RegisteredWeatherStation.find_by(reference_name: @station_id)&.name
      @weather_data = RegisteredHourlyWeather.for_station_id(@station_id).between(@started_at, @stopped_at).reorder(:started_at)
      @historical_forecast = build_daily_weather
    end

    def farm_informations
      {
        harvest_year: @campaign.harvest_year,
        farm_name: @farm.full_name,
        farm_siret: @farm.siret_number,
        farm_ape: @farm.activity_code,
        farm_legal_position: @farm.legal_position_code,
        farm_default_address: @farm_default_address&.coordinate,
        farm_default_address_lat: @farm_default_address&.latitude,
        farm_default_address_lon: @farm_default_address&.longitude,
        farm_telepac_sau: @cap_statement&.human_net_surface_area
      }
    end

    def watering_and_climatic_data
      yearly_rain = @historical_forecast.collect{|d| d[:pluviometry].to_f}.compact.sum.round(0).in(:millimeter).round_l
      yearly_min_temp = (@historical_forecast.collect{|d| d[:min_temperature].to_f}.compact.sum.round(2) / @historical_forecast.collect{|d| d[:min_temperature].to_f}.compact.count).round(2)
      yearly_max_temp = (@historical_forecast.collect{|d| d[:max_temperature].to_f}.compact.sum.round(2) / @historical_forecast.collect{|d| d[:max_temperature].to_f}.compact.count).round(2)
      {
        watering_intervention: "par mm / ha irrigué ? par mm au global ?",
        yearly_weather_day_items: @historical_forecast.count,
        yearly_weather_provider: "Météo France | Station : #{@station_name}",
        yearly_rain: yearly_rain,
        yearly_min_temp: yearly_min_temp.in(:celsius).round_l,
        yearly_max_temp: yearly_max_temp.in(:celsius).round_l
      }
    end

    def build_daily_weather
      forecast = []
      group = @weather_data.group_by { |item| item.started_at.beginning_of_day.to_date }
      group.each do |month, items|
        forecast << {
          at: month.l(format: "%d/%m/%Y"),
          humidity: (items.map(&:humidity).compact.sum / items.count).to_f.round(2),
          pluviometry: items.map(&:rain).compact.sum.to_f.round(2),
          max_wind_speed: items.map(&:max_wind_speed).compact.max,
          min_temperature: items.map(&:min_temp).compact.min,
          max_temperature: items.map(&:max_temp).compact.max,
          degree_day: items.map(&:average_temp_for_degree_day).compact.sum.round(2)
        }
      end
      forecast
    end

  end
end
