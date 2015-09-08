Ekylibre::FirstRun.add_loader :analyses do |first_run|
  first_run.import_file(:agro_systemes_soil_analyses, 'agro_systemes/analyses_sol.csv')

  first_run.import_file(:agro_systemes_water_analyses, 'agro_systemes/analyses_eau.txt')

  first_run.import_file(:lilco_milk_analyses, 'lilco/HistoIP_V.csv')

  first_run.import_file(:fiea_galactea, 'galactea3/cl_all.csv')

  first_run.import_file(:bovins_croissance_cattle_performance_controls, 'bovins_croissance/perf.csv')

  first_run.import_file(:milklic_individual_production, 'milklic/lait_individuel.csv')
end
