class AddActivityTactics < ActiveRecord::Migration
  def change
    create_table :activity_tactics do |t|
      t.references :activity, null: false, index: true
      t.string :name, null: false
      t.date :planned_on
      t.integer :mode_delta
      t.string :mode
      t.stamps
    end

    add_reference :activity_productions, :tactic, index: true
    add_column :activities, :use_tactics, :boolean, default: false
  end
end
