# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :demo do |first_run|

  if Preference.get!(:demo, false, :boolean).value

    Ekylibre::FirstRun::Faker::Sales.run(max: first_run.max)
    
    # replace by interventions.csv more real.
    # Ekylibre::FirstRun::Faker::Interventions.run(max: first_run.max)

    Ekylibre::FirstRun::Faker::Prescriptions.run(max: first_run.max)

    Ekylibre::FirstRun::Faker::Crumbs.run(max: first_run.max)

  end

end
