# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :products do |first_run|

  # load products
  path = first_run.path("alamano", "matters.csv")
  if path.exist?
   first_run.import(:ekylibre_matters, path)
  end

end
