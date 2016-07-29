class UpdatesActivityProductionsSize < ActiveRecord::Migration
  def up
    execute <<-SQL
      UPDATE activity_productions AS ap
        SET size_unit_name = a.size_unit_name,
            size_indicator_name = a.size_indicator_name,
            size_value = CASE
                         WHEN p.srid IS NULL OR p.srid = 4326 THEN ST_Area(support_shape::GEOGRAPHY)
                         ELSE ST_Area(ST_Transform(support_shape, COALESCE(p.srid))) END
                         /
                         CASE
                         WHEN a.size_unit_name = 'hectare' THEN 10000
                         WHEN a.size_unit_name = 'acre'    THEN 4046.8564224
                         WHEN a.size_unit_name = 'are'     THEN 100
                         WHEN a.size_unit_name = 'square_centimer' THEN 0.0001
                         ELSE 1 END
        FROM activities AS a,
             (SELECT CASE
                     WHEN string_value = 'WGS84' THEN 4326
                     WHEN string_value = 'RGF93' THEN 2154
                     WHEN string_value ~ '_' THEN SPLIT_PART(string_value, '_', 2)::INTEGER
                     ELSE 0 END  AS srid
               FROM preferences WHERE name = 'map_measure_srs' LIMIT 1) AS p
        WHERE a.id = ap.activity_id
          AND a.family = 'plant_farming'
          AND a.size_unit_name IN ('hectare', 'square_meter', 'acre', 'are', 'square_centimer')
    SQL
      .strip
      .gsub(/\s*\n\s+/, ' ')
  end

  # No need of down because missing value was already wanted
end
