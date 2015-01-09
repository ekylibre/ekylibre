# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :entities do |first_run|

  file = first_run.path("alamano", "entities.csv")
  if file.exist?
    first_run.import(:ekylibre_entities, file)
  end

end
