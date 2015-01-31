# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :equipments do |first_run|

  # load equipments
  path = first_run.path("alamano", "equipments.csv")
  if path.exist?
   first_run.import(:ekylibre_equipments, path)
  end

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

  # load workers
  path = first_run.path("alamano", "workers.csv")
  if path.exist?
    first_run.import(:ekylibre_workers, path)
  end


  # set default geolocations if exist
  georeadings = Georeading.where(nature: :point)
  georeadings.each do |georeading|
   if product = Product.find_by_work_number(georeading.number)
     product.read!(:geolocation, georeading.content, at: product.born_at, force: true)
   end
  end

end
