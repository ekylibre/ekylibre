class AddActivityTactics < ActiveRecord::Migration
  def change
    create_table :activity_tactics do |t|
      t.references :activity, null: false, index: true
      t.string :name, null: false
      t.date :sowed_on
      t.date :harvested_on
      t.integer :mod_quantity_delta
      t.string :mod
      t.integer :bulk_quantity
      t.integer :bulk_quantity_delta
      t.string :bulk_unit_name
      t.stamps
    end

    add_reference :activity_productions, :activity_tactic, index: true
    add_column :activities, :use_tactics, :boolean, default: false
  end
end
