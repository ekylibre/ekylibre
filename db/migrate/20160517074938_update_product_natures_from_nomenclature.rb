class UpdateProductNaturesFromNomenclature < ActiveRecord::Migration
  CHANGES = {
    cover_implanter: { frozen_indicators: 'application_width, theoretical_working_speed', variable_indicators: 'geolocation' },
    dumper: { frozen_indicators: 'nominal_storable_net_volume, nominal_storable_net_mass', variable_indicators: 'geolocation' },
    ferry: { frozen_indicators: 'nominal_storable_net_volume, nominal_storable_net_mass', variable_indicators: 'geolocation' },
    fuel_tank: { frozen_indicators: 'nominal_storable_net_volume', variable_indicators: '' },
    gas_engine: { frozen_indicators: 'application_width, nominal_storable_net_volume, theoretical_working_speed', variable_indicators: 'geolocation' },
    grinder: { frozen_indicators: 'application_width, theoretical_working_speed', variable_indicators: 'geolocation' },
    harrow: { frozen_indicators: 'application_width, theoretical_working_speed', variable_indicators: 'geolocation' },
    harvester: { frozen_indicators: 'application_width, rows_count, theoretical_working_speed', variable_indicators: 'geolocation' },
    hiller: { frozen_indicators: 'application_width, rows_count, theoretical_working_speed', variable_indicators: 'geolocation' },
    hoe: { frozen_indicators: 'application_width, rows_count, theoretical_working_speed', variable_indicators: 'geolocation' },
    implanter: { frozen_indicators: 'application_width, rows_count, theoretical_working_speed', variable_indicators: 'geolocation' },
    picker: { frozen_indicators: 'application_width, rows_count, theoretical_working_speed', variable_indicators: 'geolocation' },
    plow: { frozen_indicators: 'application_width, plowshare_count, theoretical_working_speed', variable_indicators: 'geolocation' },
    reaper: { frozen_indicators: 'application_width, theoretical_working_speed', variable_indicators: 'geolocation' },
    seedbed_preparator: { frozen_indicators: 'application_width, theoretical_working_speed', variable_indicators: 'geolocation' },
    sieve_shaker: { frozen_indicators: 'application_width, theoretical_working_speed', variable_indicators: 'geolocation' },
    soil_loosener: { frozen_indicators: 'application_width, theoretical_working_speed', variable_indicators: 'geolocation' },
    sower: { frozen_indicators: 'nominal_storable_net_volume, application_width, rows_count, theoretical_working_speed', variable_indicators: 'geolocation' },
    sprayer: { frozen_indicators: 'nominal_storable_net_volume, application_width, theoretical_working_speed', variable_indicators: 'geolocation' },
    spreader: { frozen_indicators: 'nominal_storable_net_volume, application_width, theoretical_working_speed', variable_indicators: 'geolocation' },
    steam_engine: { frozen_indicators: 'nominal_storable_net_volume, application_width, theoretical_working_speed', variable_indicators: 'geolocation' },
    superficial_plow: { frozen_indicators: 'application_width, theoretical_working_speed', variable_indicators: 'geolocation' },
    topper: { frozen_indicators: 'application_width, theoretical_working_speed', variable_indicators: 'geolocation' },
    trailer: { frozen_indicators: 'nominal_storable_net_volume, nominal_storable_net_mass', variable_indicators: 'geolocation' },
    trimmer: { frozen_indicators: 'application_width, theoretical_working_speed', variable_indicators: 'geolocation' },
    uncover: { frozen_indicators: 'application_width, theoretical_working_speed', variable_indicators: 'geolocation' },
    water_tank: { frozen_indicators: 'nominal_storable_net_volume', variable_indicators: 'geolocation' },
    weeder: { frozen_indicators: 'application_width, theoretical_working_speed', variable_indicators: 'geolocation' },
    wine_tank: { frozen_indicators: 'nominal_storable_net_volume', variable_indicators: 'geolocation' },
    corn_topper: { frozen_indicators: 'application_width, theoretical_working_speed', category: 'equipment', variety: 'equipment', variable_indicators: 'geolocation' }
  }.freeze
  def change
    CHANGES.each do |reference_name, fields|
      query =  'UPDATE product_natures SET lock_version = lock_version + 1'
      query << ", frozen_indicators_list = #{quote fields[:frozen_indicators]}" if fields[:frozen_indicators]
      query << ", variable_indicators_list = #{quote fields[:variable_indicators]}" if fields[:variable_indicators]
      query << ", variety = #{quote fields[:variety]}" if fields[:variety]
      if fields[:category]
        # FIXME: Remove model to be independant of... models
        ProductNatureCategory.import_from_nomenclature(fields[:category])
        category_id = select_value('SELECT id FROM product_nature_categories WHERE reference_name = ' + quote(fields[:category].to_s)).to_i
        query << ", category_id = #{category_id}"
      end

      query << " WHERE reference_name = #{quote reference_name.to_s}"
      execute query
    end
  end
end
