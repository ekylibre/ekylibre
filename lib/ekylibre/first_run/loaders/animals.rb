# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :animals do |first_run|
  
  first_run.import_file(:ekylibre_animal_groups, "alamano/animal_groups.csv")
  first_run.import_pictures("alamano/animal_groups", :products, :work_number)

  first_run.import_file(:ekylibre_animals, "alamano/animals.csv")
  first_run.import_pictures("alamano/animals", :products, :work_number)

  first_run.import_file(:upra_reproductors, "upra/liste_males_reproducteurs.txt")

  first_run.import_file(:synel_animals, "synel/animaux.csv")
  first_run.import_file(:synel_inventory, "synel/inventaire.csv")

end
