# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :purchases do |first_run|

  #import purchases
  file = first_run.path("alamano", "purchases.csv")
  if file.exist?
    first_run.import(:ekylibre_purchases, file)
  end

  #import outgoing_payments link to purchase
  path = first_run.path("alamano", "outgoing_payments.csv")
  if path.exist?
    first_run.import(:ekylibre_outgoing_payments, path)
  end

  #import original purchase files
  # TODO compress all files inside purchases.zip
  path = first_run.path("alamano", "documents", "purchases.zip")
  if path.exist?
    first_run.import(:ekylibre_original_purchase_files, path)
  end

end
