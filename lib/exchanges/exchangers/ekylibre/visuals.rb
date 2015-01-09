# Create or updates entities
Exchanges.add_importer :ekylibre_visuals do |file, w|
  w.count = 1

  Ekylibre::CorporateIdentity::Visual.set_default_background(file)
  w.check_point
end
