Ekylibre::FirstRun.add_loader :interventions do |first_run|
  # Import interventions from Ekylibre conventions
  first_run.import_file(:ekylibre_interventions, 'alamano/interventions.csv')

  # Import interventions from viniteca
  first_run.import_archive(:viniteca_interventions, 'viniteca_intervention.zip', 'variants_transcode.csv', 'issue_natures_transcode.csv', 'procedures_transcode.csv', 'interventions.csv', in: 'viniteca')

  # Import interventions from isaculture files
  first_run.import_archive(:isagri_isaculture_csv_import, 'isaculture.zip', 'procedures_transcode.csv', 'cultivable_zones_transcode.csv', 'variants_transcode.csv', 'units_transcode.csv', 'workers_transcode.csv', 'equipments_transcode.csv', 'interventions.csv', in: 'isaculture')

end
