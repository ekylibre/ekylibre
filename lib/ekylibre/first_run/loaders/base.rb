Ekylibre::FirstRun.add_loader :base do |first_run|

  path = first_run.path("manifest.yml")
  if path.exist?
    first_run.import(:ekylibre_settings, path, max: 0)
  end

  path = first_run.path("alamano", "background.jpg")
  if path.exist?
    first_run.import(:ekylibre_visuals, path)
  end

  # set extensions
  extensions = ['jpeg','jpg','png']
  # load default logo for of_company
  if entity_of_company = Entity.of_company
    for extension in extensions
      picture_path = first_run.path("alamano", "logo.#{extension}")
      f = (picture_path.exist? ? File.open(picture_path) : nil)
      if f
       entity_of_company.update!(picture: f)
       f.close
      end
    end
  end

end
