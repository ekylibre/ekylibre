class FixedAssetsStoppedAtUpdate < ActiveRecord::Migration[5.0]
  def up
    execute <<~SQL
      UPDATE fixed_assets
      SET stopped_on = sold_on
      WHERE sold_on IS NOT NULL
    SQL

    execute <<~SQL
      UPDATE fixed_assets
      SET stopped_on = scrapped_on
      WHERE scrapped_on IS NOT NULL
    SQL
  end
end