class ChangeEvents< ActiveRecord::Migration
  def up
    remove_column :animal_events, :treatment_id
    remove_column :animal_treatments, :prescriptor_id
    remove_column :animal_treatments, :prescription_number
    remove_column :animal_treatments, :per_unit
    remove_column :animal_treatments, :unit_id
  end

  def down
    add_column :animal_events, :treatment_id, :integer
    add_column :animal_treatments, :prescriptor_id, :integer
    add_column :animal_treatments, :prescription_number, :string
    add_column :animal_treatments, :per_unit, :string
    add_column :animal_treatments, :unit_id, :integer
  end

end