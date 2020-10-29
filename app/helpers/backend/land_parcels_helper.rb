module Backend
  module LandParcelsHelper
    def land_parcels_map(options = {})
      janus = options.delete(:janus)
      html_options ||= {}
      html_options[:class] = 'map-fullwidth'
      html = visualization(options.merge(box: { height: '100%' }, async_url: backend_visualizations_land_parcels_visualizations_path), html_options) do |v|
        v.control :zoom
        v.control :scale
        v.control :fullscreen
        v.control :layer_selector
        if LandParcel.last && LandParcel.last.shape_centroid.present?
          v.center LandParcel.last.shape_centroid
        end
      end

      if janus
        janus.face :map do
          html
        end
      else
        html
      end
    end
  end
end
