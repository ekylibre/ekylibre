Ekylibre::FirstRun.add_loader :productions do |first_run|

  unless Preference.get!(:create_activities_from_telepac, false, :boolean).value
    # Load activities
    first_run.try_import(:ekylibre_activities, "alamano/activities.csv")
  end

  # Load budgets
  first_run.try_import(:ekylibre_budgets, "alamano/budgets.ods")

end
