class AddCultivableZoneToAnalysis < ActiveRecord::Migration[5.0]
  def change
    add_reference :analyses, :cultivable_zone, index: true, foreign_key: { to_table: :cultivable_zones }
  end
end
