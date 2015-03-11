# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :products do |first_run|

  # Load matters
  first_run.try_import(:ekylibre_matters, "alamano/matters.csv")

end
