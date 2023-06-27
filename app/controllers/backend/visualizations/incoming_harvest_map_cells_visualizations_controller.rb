module Backend
  module Visualizations
    class IncomingHarvestMapCellsVisualizationsController < Backend::VisualizationsController
      respond_to :json

      def show
        config = {}
        data = []

        campaigns = params[:campaigns]
        ihc = IncomingHarvestIndicator.of_campaign(campaigns)

        if ihc.any?
          ihc.each do |ih_crop_indicator|
            crop = ih_crop_indicator.crop
            ap = ih_crop_indicator.activity_production
            next unless ap.support_shape

            area = Measure.new(ih_crop_indicator.crop_area_value, ih_crop_indicator.crop_area_unit)
            popup_content = []
            # popup_content << {label: :campaign.tl, value: view_context.link_to(params[:campaigns.name, backend_campaign_path(params[:campaigns))}
            popup_content << { label: ActivityProduction.human_attribute_name(:net_surface_area), value: area.l }
            popup_content << { label: ActivityProduction.human_attribute_name(:activity), value: view_context.link_to(ap.activity_name, backend_activity_path(ap.activity)) }

            ihc_yield = Measure.new(ih_crop_indicator.crop_incoming_harvest_yield_value, ih_crop_indicator.crop_incoming_harvest_yield_unit)
            # TODO: refactor yield informations adn reactivate it
            grass_yield = 0.0
            grain_yield = 0.0
            vegetable_yield = 0.0
            fruit_yield = 0.0
            # case fodder (hay, grass) in ton per hectare
            if area.to_f > 0.0
              if %w[fodder fiber meadow fallow_land].include?(ap.usage)
                label = :grass_yield
                grass_yield = ihc_yield.convert(:ton_per_hectare)
                popup_content << { label: label.tl, value: grass_yield.round(2).l }
              # case grain in quintal per hectare
              elsif %w[seed grain].include?(ap.usage)
                label = :grain_yield
                grain_yield = ihc_yield.convert(:quintal_per_hectare)
                popup_content << { label: label.tl, value: grain_yield.round(2).l }
              # case vegetable
              elsif ap.usage == 'vegetable'
                label = :vegetable_yield
                if %w[ton_per_hectare quintal_per_hectare kilogram_per_hectare].include?(ihc_yield.unit)
                  vegetable_yield = ihc_yield.convert(:ton_per_hectare)
                elsif %w[unit_per_hectare unity_per_hectare head_per_hectare thousand_per_hectare].include?(ihc_yield.unit)
                  vegetable_yield = ihc_yield.convert(:thousand_per_hectare)
                end
                popup_content << { label: label.tl, value: vegetable_yield.round(2).l }
              # grappe
              elsif %w[grappe fruit].include?(ap.usage)
                label = :fruit_yield
                fruit_yield = ihc_yield.convert(:ton_per_hectare)
                popup_content << { label: label.tl, value: fruit_yield.round(2).l }
              end
            end

            item = {
              name: ap.name,
              shape: ap.support_shape,
              shape_color: ap.activity.color,
              activity: ap.activity.name,
              grain_yield: grain_yield.to_s.to_f.round(2),
              grass_yield: grass_yield.to_s.to_f.round(2),
              vegetable_yield: vegetable_yield.to_s.to_f.round(2),
              fruit_yield: fruit_yield.to_s.to_f.round(2),
              popup: { header: true, content: popup_content }
            }
            data << item
          end

          config = view_context.configure_visualization do |v|
            v.serie :main, data
            v.categories :activity, :main
            v.choropleth :grain_yield, :main, stop_color: '#FA2908'
            v.choropleth :grass_yield, :main, stop_color: '#00AA00'
            v.choropleth :vegetable_yield, :main, stop_color: '#FA2908'
            v.choropleth :fruit_yield, :main, stop_color: '#AA00AA'
          end

        end

        respond_with config
      end
    end
  end
end
