module Backend
  module InspectionsHelper
    def data_series(inspection, method, dataset, unit)
      # net_surface_area = inspection.product_net_surface_area_value
      dataset.map do |calibration|
        result = calibration.send(method).round(0).to_d(unit).to_s.to_f.round(2)
        next if result.zero?
        if block_given?
          yield(calibration.name, result)
        else
          { name: calibration.name, y: result}
        end
      end
    end
  end
end
