# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :general_ledger do |first_run|

  first_run.import_file(:bordeaux_sciences_agro_istea_general_ledger, "istea/general_ledger.txt")

  first_run.import_file(:bordeaux_sciences_agro_istea_journals, "istea/journals.csv")

end
