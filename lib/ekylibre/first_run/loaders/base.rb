Ekylibre::FirstRun.add_loader :base do |first_run|

  first_run.import_file(:ekylibre_settings, "manifest.yml", max: 0)

  first_run.import_file(:ekylibre_visuals, "alamano/background.jpg")

  first_run.import_file(:ekylibre_backup, "ekylibre/backup.zip")

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
