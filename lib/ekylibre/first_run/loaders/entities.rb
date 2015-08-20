Ekylibre::FirstRun.add_loader :entities do |first_run|
  first_run.import_file(:ekylibre_entities, 'alamano/entities.csv')

  first_run.import_archive(:la_graine_informatique_vinifera_entities, 'entities.zip', 'entities.csv', 'client_types_transcode.csv', 'client_price_types_transcode.csv', 'client_origins_transcode.csv', 'client_qualities_transcode.csv', 'client_evolutions_transcode.csv', 'custom_fields.csv', in: 'vinifera')
end
