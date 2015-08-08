Ekylibre::FirstRun.add_loader :deliveries do |first_run|
  first_run.import_file(:charentes_alliance_incoming_deliveries, 'charentes_alliance/appros.csv')

  first_run.import_archive(:charentes_alliance_outgoing_deliveries, 'apports.zip', 'apports.csv', 'silo_transcode.csv', in: 'charentes_alliance')

  first_run.import_file(:unicoque_outgoing_deliveries, 'unicoque/recolte.csv')
end
