Ekylibre::FirstRun.add_loader :equipments do |first_run|
  # Load equipments
  first_run.import_file(:ekylibre_equipments, 'alamano/equipments.csv')
  first_run.import_pictures('alamano/equipments', :products, :work_number)

  # Load workers
  first_run.import_file(:ekylibre_workers, 'alamano/workers.csv')
  first_run.import_pictures('alamano/workers', :products, :work_number)
end
