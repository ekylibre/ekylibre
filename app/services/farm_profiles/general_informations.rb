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
        farm_associates: associates,
        farm_soil_analysis: soil_analysis,
        farm_telepac_sau: @cap_statement&.human_net_surface_area,
        farm_fallow_area: fallow_area,
        farm_meadow_area: meadow_area,
        farm_big_crop_area: big_crop_area
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
        yearly_max_temp: yearly_max_temp.in(:celsius).round_l,
        first_frozen_day: @weather_data.where("min_temp <= 0.0 AND EXTRACT(MONTH from started_at) > 08").reorder(:started_at).first.started_at.l,
        last_frozen_day: @weather_data.where("min_temp <= 0.0 AND EXTRACT(MONTH from started_at) < 06").reorder(:started_at).last.started_at.l,
        yearly_min_frozen_temp: @weather_data.where("min_temp <= 0.0").reorder(:min_temp).first.min_temp.in(:celsius).round_l
      }
    end

    def crop_rotations(year = :current)
      # N
      if year == :current
        c = @campaign
      # N - 1
      elsif year == :preceding
        c = @campaign.preceding
      # N -2
      elsif year == :antepreceding
        c = @campaign.preceding.preceding
      end
      activity_rotation = []
      Activity.main_of_campaign(c).of_family(:plant_farming).each do |act|
        activity_rotation << {
          name: act.name,
          variety: act.cultivation_variety,
          net_surface_area: act.support_shape_area(c).convert(:hectare).round(2),
          color: act.color
        }
      end
      activity_rotation
    end

    def biodiversity_informations
      {
        edges_total_length: edges_total_length,
        biodiversity_area: (grass_borders + boskets_and_ponds_area)
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

    #
    # unit method indicator
    #

    def associates
      ass = []
      Associate.all.each do |a|
        ass << {
          full_name: a.entity.full_name,
          started_at: a.started_on.l
        }
      end
      ass
    end

    def soil_analysis
      an = Analysis.where(nature: 'soil_analysis').reorder(:analysed_at).last
      if an.present?
        {
          analysed_at: an.analysed_at.l,
          geolocation: an.geolocation.to_geojson,
          soil_nature: an.items.where(indicator_name: 'soil_nature')&.first&.value,
          potential_hydrogen: an.items.where(indicator_name: 'potential_hydrogen')&.first&.value,
          organic_matter_concentration: an.items.where(indicator_name: 'organic_matter_concentration')&.first&.value
        }
      else
        {}
      end
    end

    def fallow_area
      aps = ActivityProduction.of_campaign(@campaign).where(usage: %w[fallow_land], support_nature: 'cultivation')
      if aps.present?
        aps.pluck(:size_value).compact.sum.round(2).to_f
      else
        0.0
      end
    end

    def meadow_area
      # Look for all meadow reference name for campaign in activity productions
      aps = ActivityProduction.of_campaign(@campaign).where(reference_name: %w[meadow])
      if aps.present?
        aps.pluck(:size_value).compact.sum.round(2).to_f
      else
        0.0
      end
    end

    def big_crop_area
      aps = ActivityProduction.of_campaign(@campaign).of_cultivation_varieties(Onoma::CropSet.find('field_industrial_fodder_crops_idea').varieties)
      if aps.present?
        aps.pluck(:size_value).compact.sum.round(2).to_f
      else
        0.0
      end
    end

    def edges_total_length
      buffer = 0.7
      geometries = CultivableZone.all.map(&:shape).compact.uniq
      edges = RegisteredAreaItem.of_nature(:edge).buffer_intersecting(buffer, *geometries)
      if edges.present?
        total = 0.0
        edges.each do |edge|
          total += edge.geometry.to_rgeo.length
        end
        total.round(2).in_meter.to_f
      else
        0.0
      end
    end

    def grass_borders(unit = :hectare)
      a_grass_borders = CapLandParcel.of_campaign(@campaign).where(main_crop_code: %w[BFS BOR BTA])
      if a_grass_borders.present?
        total = a_grass_borders.geom_union(:shape).area
        total.in_square_meter.convert(unit).to_f.round(4)
      else
        0.0
      end
    end

    def boskets_and_ponds_area(unit = :hectare)
      a_boskets = CapNeutralArea.of_campaign(@campaign).where(nature: %w[V3 A1])
      if a_boskets.present?
        total = a_boskets.geom_union(:shape).area
        total.in_square_meter.convert(unit).to_f.round(4)
      else
        0.0
      end
    end

  end
end
