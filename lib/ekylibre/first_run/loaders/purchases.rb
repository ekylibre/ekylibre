# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :purchases do |first_run|

  # Load purchases
  first_run.try_import(:ekylibre_purchases, "alamano/purchases.csv")

  # Load outgoing_payments link to purchase
  first_run.try_import(:ekylibre_outgoing_payments, "alamano/outgoing_payments.csv")

  #import original purchase files
  # TODO compress all files inside purchases.zip
  first_run.try_import(:ekylibre_original_purchase_files, "alamano/documents/purchases.zip")

end
