Ekylibre::FirstRun.add_loader :demo do |first_run|
  if Preference.value(:demo, false)

    # replace by sales.csv / purchases.csv more real.
    # Ekylibre::FirstRun::Faker::Sales.run(max: first_run.max)

    # replace by interventions.csv more real.
    # Ekylibre::FirstRun::Faker::Interventions.run(max: first_run.max)
    
    # TODO adapt for interventions v2
    # Ekylibre::FirstRun::Faker::Prescriptions.run(max: first_run.max)
    # Ekylibre::FirstRun::Faker::Crumbs.run(max: first_run.max)

  end
end
