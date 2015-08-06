class AddActivityDistributions < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute "UPDATE activities SET nature = 'standalone' WHERE nature ='none'"
        change_column :activities, :description, :text
        remove_column :activities, :depth
        remove_column :activities, :lft
        remove_column :activities, :rgt
        remove_column :activities, :parent_id
      end
      dir.down do
        add_reference :activities, :parent, index: true
        add_column :activities, :rgt, :integer
        add_column :activities, :lft, :integer
        add_column :activities, :depth, :integer
        execute "UPDATE activities SET nature = 'none' WHERE nature ='standalone'"
      end
    end

    create_table :activity_distributions do |t|
      t.references :activity, null: false, index: true
      t.decimal :affectation_percentage, precision: 19, scale: 4, null: false
      t.references :main_activity, null: false, index: true
      t.stamps
    end

    create_table :production_distributions do |t|
      t.references :production, null: false, index: true
      t.decimal :affectation_percentage, precision: 19, scale: 4, null: false
      t.references :main_production, null: false, index: true
      t.stamps
    end
  end
end
