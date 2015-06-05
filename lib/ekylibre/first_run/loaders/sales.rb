Ekylibre::FirstRun.add_loader :sales do |first_run|

  # Import sales
  first_run.import_file(:ekylibre_sales, "alamano/sales.csv")

  # Import incoming link to sale
  first_run.import_file(:ekylibre_incoming_payments, "alamano/incoming_payments.csv")

end
