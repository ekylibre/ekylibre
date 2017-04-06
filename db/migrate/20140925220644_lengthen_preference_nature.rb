class LengthenPreferenceNature < ActiveRecord::Migration
  def change
    change_column :preferences, :nature, :string, limit: 60
    execute "UPDATE preferences SET name='chart_of_accounts', nature='chart_of_accounts' WHERE name='chart_of_account'"
    for pref in %i[language country currency]
      execute "UPDATE preferences SET nature='#{pref}' WHERE name='#{pref}'"
    end
    execute "UPDATE preferences SET name='map_measure_srs', string_value = CASE WHEN integer_value = 2154 THEN 'RGF93' ELSE 'WGS84' END, nature='spatial_reference_system' WHERE name = 'map_measure_srid'"
  end
end
