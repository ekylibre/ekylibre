class RemoveAnalyticDistributions < ActiveRecord::Migration

  def change
    reversible do |dir|
      dir.up do
        drop_table :analytic_distributions
      end
      dir.down do
        create_table :analytic_distributions do |t|
          t.references :production,                                                 null: false, index: true
          t.references :journal_entry_item,                                         null: false, index: true
          t.string   "state",                                                       null: false
          t.datetime "affected_at",                                                 null: false
          t.decimal  "affectation_percentage", precision: 19, scale: 4,             null: false
          t.stamps
        end
      end
    end
  end

end
