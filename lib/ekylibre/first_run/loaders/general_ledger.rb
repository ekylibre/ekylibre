# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :general_ledger do |first_run|

  file = first_run.path("istea", "general_ledger.txt")
  if file.exist?
    first_run.import(:bordeaux_sciences_agro_istea_general_ledger, file)
  end

  file = first_run.path("istea", "journals.csv")
  if file.exist?
    first_run.import(:bordeaux_sciences_agro_istea_journals, file)
  end

end
