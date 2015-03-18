Ekylibre::FirstRun.add_loader :productions do |first_run|

  # Load budgets
  first_run.import_file(:ekylibre_budgets, "alamano/budgets.ods")

end
