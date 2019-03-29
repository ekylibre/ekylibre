module Backend
  module LandParcelsHelper
    def land_parcels_map(options = {})
      options[:collection] ||= LandParcel.all
      main_serie = []
      options[:collection].each do |p|
        land_parcel_shape = p.shape
        next unless land_parcel_shape

        popup_content = []

        # for all land_parcel
        popup_content << {
          label: Nomen::Indicator[:net_surface_area].human_name,
          value: p.net_surface_area.to_d(:hectare).round(2).l
        }

        # for indicators in list
        indicators = %i[soil_nature potential_hydrogen available_water_capacity_per_area soil_depth organic_matter_concentration]
        available_indicators = (p.readings.map(&:indicator_name).map(&:to_sym) & indicators)

        serie = {
          name: p.name,
          shape: land_parcel_shape,
          potential_hydrogen: 0.0,
          organic_matter_concentration: 0.0,
          available_water_capacity_per_area: 0.0,
          soil_nature: :unknown.tl
        }

        available_indicators.each do |indicator|
          indicator_value = p.send(indicator)
          next unless indicator_value.present? && (indicator_value.to_d > 0.0)

          if indicator == :soil_nature
            soil_nature = Nomen::SoilNature[p.soil_nature]
            serie[:soil_nature] = soil_nature ? soil_nature.human_name : :unknown.tl
          else
            serie[indicator] = indicator_value.to_d
          end

          popup_content << {
            label: Nomen::Indicator[indicator].human_name,
            value: indicator_value.l
          }
        end

        popup_content << render('popup', land_parcel: p)

        serie[:popup] = { header: true, content: popup_content }
        main_serie << serie
      end

      if main_serie.any?
        html = collection_map(main_serie, main: true) do |v|
          v.bubbles :available_water_capacity_per_area, :main, label: Nomen::Indicator[:available_water_capacity_per_area].human_name
          v.choropleth :organic_matter_concentration, :main, hidden: true, label: Nomen::Indicator[:organic_matter_concentration].human_name
          v.choropleth :potential_hydrogen, :main, hidden: true, label: Nomen::Indicator[:potential_hydrogen].human_name
          v.categories :soil_nature, :main
        end

        if options[:janus]
          options[:janus].face :map do
            html
          end
        else
          return html
        end
      end
    end
  end
end
