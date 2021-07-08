class ChangeProductionReferenceInProductions < ActiveRecord::Migration[5.0]

  def change
    add_column :activity_productions, :reference_name, :string

    execute <<~SQL
      UPDATE activity_productions
        SET reference_name = (SELECT reference_name FROM activities WHERE activities.id = activity_productions.activity_id)
      WHERE production_nature_id IS NOT NULL;
    SQL

    remove_column :activity_productions, :production_nature_id
  end
end
