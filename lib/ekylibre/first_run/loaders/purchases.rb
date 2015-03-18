# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :purchases do |first_run|

  # Import purchases
  first_run.import_file(:ekylibre_purchases, "alamano/purchases.csv")

  # Import outgoing_payments link to purchase
  first_run.import_file(:ekylibre_outgoing_payments, "alamano/outgoing_payments.csv")

  # Import original purchase files
  # TODO compress all files inside purchases.zip
  first_run.import_file(:ekylibre_original_purchase_files, "alamano/documents/purchases.zip")

end
