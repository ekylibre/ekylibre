# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :products do |first_run|
  # Load matters
  first_run.import_file(:ekylibre_matters, 'alamano/matters.csv')

  first_run.import_archive(:la_graine_informatique_vinifera_products, 'products.zip', 'products.csv', 'units_transcode.csv', 'variants_transcode.csv', in: 'vinifera')

end
