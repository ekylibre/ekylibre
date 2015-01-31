# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :buildings do |first_run|

  path = first_run.path("alamano", "zones.csv")
  if path.exist?
    first_run.import(:ekylibre_zones, path)
  end

end
