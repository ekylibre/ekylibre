class AddCultivableZoneToRides < ActiveRecord::Migration[5.1]
  def change
    add_reference :rides, :cultivable_zone, foreign_key: true
  end
end
