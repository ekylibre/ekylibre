class ConvertPointsToPostgisPoints < ActiveRecord::Migration

  CONVERSIONS = {
    analyses: :geolocation,
    analysis_items: :point_value,
    crumbs: :geolocation,
    entity_addresses: :mail_geolocation,
    issues: :geolocation,
    product_nature_variant_readings: :point_value,
    product_reading_tasks: :point_value,
    product_readings: :point_value,
    production_support_markers: :point_value,
    products: :initial_geolocation
  }

  def up
    CONVERSIONS.each do |table, column|
      bad_column = "#{column}__"
      rename_column table, column, bad_column
      add_column table, column, :st_point, srid: 4326
      execute "UPDATE #{table} SET #{column} = ST_SetSRID(ST_Point(#{bad_column}[0], #{bad_column}[1]), 4326)"
      remove_column table, bad_column
    end
  end

  def down
    CONVERSIONS.each do |table, column|
      bad_column = "#{column}__"
      add_column table, bad_column, :point
      execute "UPDATE #{table} SET #{bad_column} = ('(' || ST_X(#{column}) || ', ' || ST_Y(#{column}) || ')')::POINT"
      remove_column table, column
      rename_column table, bad_column, column
    end
  end

end
