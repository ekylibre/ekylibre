module Backend::InspectionsHelper
  def data_series(inspection, method, dataset, unit)
    net_surface_area = inspection.product_net_surface_area_value
    dataset.map do |calibration|
      yield(calibration.name, calibration.send(method).round(0).to_d(unit).to_s.to_f)
    end
  end
end
