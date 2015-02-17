# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :productions do |first_run|

  #############################################################################
  unless Preference.get!(:create_activities_from_telepac, false, :boolean).value
    # load activities
    path = first_run.path("alamano", "activities.csv")
    if path.exist?
     first_run.import(:ekylibre_activities, path)
    end
  end

  # load budgets
  path = first_run.path("alamano", "budgets.ods")
  if path.exist?
   first_run.import(:ekylibre_budgets, path)
  end

end
