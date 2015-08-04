Ekylibre::FirstRun.add_loader :bank_statements do |first_run|
  # Import bank statements
  first_run.import_file(:ekylibre_bank_statements, 'alamano/bank_statements.ods')
end
