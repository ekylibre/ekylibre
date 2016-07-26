class AttachPlantDensityAbaciToActivities < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE
            plant_density_abaci AS pda
            SET activity_id = act.id
            FROM activities AS act
            WHERE pda.name LIKE CONCAT(act.name, '%')
                AND pda.activity_id IS NULL;
        SQL
        execute <<-SQL
          UPDATE
            plant_density_abaci AS pda
            SET activity_id = act.id
            FROM activities AS act
            WHERE pda.name LIKE CONCAT('%', act.name)
                AND pda.activity_id IS NULL;
        SQL
        execute <<-SQL
          UPDATE
            plant_density_abaci AS pda
            SET activity_id = act.id
            FROM activities AS act
            WHERE pda.name LIKE CONCAT('%', act.name, '%')
                AND pda.activity_id IS NULL;
        SQL
        execute <<-SQL
          UPDATE
            plant_density_abaci AS pda
            SET activity_id = 1
            WHERE pda.activity_id IS NULL;
        SQL
      end
      dir.down do
        raise ActiveRecord::IrreversibleMigration
      end

      change_column :plant_density_abaci, :activity_id, :integer, null: false
    end
  end
end
