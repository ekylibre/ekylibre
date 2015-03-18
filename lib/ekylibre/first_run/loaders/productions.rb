Ekylibre::FirstRun.add_loader :productions do |first_run|

  # Load budgets
  first_run.try_import(:ekylibre_budgets, "alamano/budgets.ods")

end
