Ekylibre::FirstRun.add_loader :base do |first_run|

  path = first_run.path("manifest.yml")
  if path.exist?
    first_run.import(:ekylibre_settings, path, max: 0)
  end

  path = first_run.path("alamano", "background.jpg")
  if path.exist?
    first_run.import(:ekylibre_visuals, path)
  end

end
