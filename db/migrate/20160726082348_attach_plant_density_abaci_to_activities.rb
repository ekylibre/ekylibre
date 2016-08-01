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
            SET activity_id = activities.id
            FROM activities
            WHERE pda.activity_id IS NULL;
        SQL
        change_column :plant_density_abaci, :activity_id, :integer, null: false
      end
      dir.down do
        change_column :plant_density_abaci, :activity_id, :integer, null: true
      end
    end
  end
end
