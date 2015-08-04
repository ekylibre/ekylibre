# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :entities do |first_run|
  first_run.import_file(:ekylibre_entities, 'alamano/entities.csv')

  first_run.import_file(:la_graine_informatique_vinifera_entities, 'vinifera/entities.csv')
end
