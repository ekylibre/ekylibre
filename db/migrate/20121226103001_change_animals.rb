class ChangeAnimals< ActiveRecord::Migration
  def change

      add_column :animals, :working_number, :string
      add_column :animals, :owner_id, :integer

      add_column :animal_treatments, :event_id, :integer

      rename_table :diagnostics, :animal_diagnostics
      add_column :animal_diagnostics, :corpse_location, :string

      rename_table :drugs, :animal_drugs
      rename_table :posologies, :animal_posologies
      rename_table :prescriptions, :animal_prescriptions

  end
end