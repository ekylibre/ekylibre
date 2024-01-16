module Backend
  module Visualizations
    class WeatherStationMapCellsVisualizationsController < Backend::VisualizationsController
      respond_to :json

      def show
        config = {}

        sensor_data = []
        # farm position
        entity_full_name = Entity.of_company.full_name
        farm_header_content = "<span class='sensor-name'>#{entity_full_name}</span>".html_safe
        sensor_data << {
          sensor_id: '1',
          name: entity_full_name,
          shape: params[:shape_centroid],
          shape_color: '#FA1304',
          group: entity_full_name,
          popup: { header: farm_header_content, content: [] }
        }
        # weather station position
        stations = RegisteredWeatherStation.where(reference_name: params[:station_ids])
        stations.each do |station|
          popup_lines = []
          if Preference[:weather_public_station] == station.reference_name
            color = '#83fe00'
          else
            color = '#14FFF8'
            popup_lines << { value: view_context.link_to(
              :use_this_weather_station.tl,
              { controller: "/backend/companies",
                action: :set_station_as_default,
                station_id: station.reference_name },
              class: 'btn btn-primary'
            ) }
          end
          header_content = "<span class='sensor-name'>#{station.station_name} | #{station.reference_name}</span>".html_safe
          s_items = {
                sensor_id: station.reference_name,
                name: station.station_name,
                shape: station.centroid,
                shape_color: color,
                group: station.country_zone,
                popup: { header: header_content, content: popup_lines }
              }
          sensor_data << s_items
        end

        config = view_context.configure_visualization do |v|
          v.serie :main, sensor_data
          v.point_group :public_weather_stations, :main
        end

        respond_with config
      end
    end
  end
end
