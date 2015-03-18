Ekylibre::FirstRun.add_loader :sales do |first_run|

  # Import sales
  first_run.import_file(:ekylibre_sales, "alamano/sales.csv")

end
