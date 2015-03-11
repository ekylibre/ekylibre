# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :interventions do |first_run|


  # Import interventions from Ekylibre conventions
  first_run.try_import(:ekylibre_interventions, "alamano/interventions.csv")

  # Import interventions from viniteca
  file = first_run.check_archive("viniteca_intervention.zip", "variants_transcode.csv", "issue_natures_transcode.csv", "procedures_transcode.csv", "interventions.csv", in: "viniteca")
  if file.exist?
    first_run.import(:viniteca_interventions, file)
  end

  # Import interventions from isaculture files
  file = first_run.check_archive("isaculture.zip", "procedures_transcode.csv", "cultivable_zones_transcode.csv", "variants_transcode.csv", "units_transcode.csv", "workers_transcode.csv", "equipments_transcode.csv", "interventions.csv", in: "isaculture")
  if file.exist?
    first_run.import(:isagri_isaculture_csv_import, file)
  end


end
