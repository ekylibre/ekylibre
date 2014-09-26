# -*- coding: utf-8 -*-
Ekylibre::FirstRun.add_loader :base do |first_run|

  path = first_run.path("manifest.yml")
  if path.exist?
    first_run.import(:ekylibre_erp_settings, path, max: 0)
  end

  path = first_run.path("alamano", "background.jpg")
  if path.exist?
    first_run.import(:ekylibre_erp_visuals, path)
  end

end
