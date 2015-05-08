class Ekylibre::PlantsExchanger < ActiveExchanger::Base

  def import
    rows = CSV.read(file, headers: true).delete_if{|r| r[0].blank?}
    w.count = rows.size

    rows.each do |row|
      r = {
        name: row[0].to_s.strip,
        work_number: row[1].to_s.strip,
        variant: (row[2].blank? ? nil : row[2].to_sym),
        container_number: (row[3].blank? ? nil : row[3].to_s.strip),
        born_at: (row[4].blank? ? nil : row[4].to_datetime),
        variety: (row[5].blank? ? nil : row[5].to_s.strip),
        indicators: row[6].blank? ? {} : row[6].to_s.strip.split(/[[:space:]]*\;[[:space:]]*/).collect{|i| i.split(/[[:space:]]*\:[[:space:]]*/)}.inject({}) { |h, i|
          h[i.first.strip.downcase.to_sym] = i.second
          h
        },
        georeading_number: (row[7].blank? ? nil : row[7].to_s)
      }.to_struct

      # find or import from variant reference_nameclature the correct ProductNatureVariant
      variant = ProductNatureVariant.import_from_nomenclature(r.variant)
      # find the container
      unless container = Product.find_by_work_number(r.container_number)
        raise "No container for cultivation!"
      end

      # create the plant
      product = variant.matching_model.create!(:variant_id => variant.id,
                                               :work_number => r.work_number,
                                               :name => r.name,
                                               :initial_born_at => r.born_at,
                                               :initial_owner => Entity.of_company,
                                               :variety => r.variety,
                                               :initial_container => container)

      # Create indicators linked to plant
      for indicator, value in r.indicators
        product.read!(indicator, value, at: r.born_at, force: true)
      end

      # Adds shape
      if r.georeading_number.present? and georeading = Georeading.find_by(number: r.georeading_number)
        product.read!(:shape, georeading.content, at: r.born_at, force: true)
      elsif container and shape = container.shape(r.born_at)
        product.read!(:shape, shape, at: r.born_at, force: true)
      end

      w.check_point
    end
  end

end
