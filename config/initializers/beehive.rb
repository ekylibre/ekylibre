Rails.application.config.x.beehive.cell_controller_types =
  Dir.entries(Rails.root.join('app/controllers/backend/cells'))
     .reject{ |f| File.directory?(f) || ["base_controller.rb", "weather_cells_base_controller.rb"].include?(File.basename(f))}
     .map { |path| path.gsub(/_cells_controller.rb$/, '').to_sym }
     .compact
