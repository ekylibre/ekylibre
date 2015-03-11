# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :equipments do |first_run|

  # Load equipments
  first_run.try_import(:ekylibre_equipments, "alamano/equipments.csv")


  # FIXME No more code wanted like that in loaders
  # attach picture if exist for each equipment
  for equipment in Equipment.all
    picture_path = first_run.path("alamano", "equipments_pictures", "#{equipment.work_number}.jpg")
    f = (picture_path.exist? ? File.open(picture_path) : nil)
    if f
      equipment.picture = f
      equipment.save!
      f.close
    end
  end

  # Load workers
  first_run.try_import(:ekylibre_workers, "alamano/workers.csv")


  # FIXME No more code wanted like that in loaders
  # set default geolocations if exist
  Georeading.where(nature: :point).each do |georeading|
    if product = Product.find_by_work_number(georeading.number)
      product.read!(:geolocation, georeading.content, at: product.born_at, force: true)
    end
  end

end
