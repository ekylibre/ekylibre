class CreateRegularizations < ActiveRecord::Migration
  def change
    reversible do |r|
      r.up do
        execute 'UPDATE affairs SET debit = credit, credit = debit'
      end
      r.down do
        execute 'UPDATE affairs SET debit = credit, credit = debit'
      end
    end

    create_table :regularizations do |t|
      t.references :affair, index: true, null: false, foreign_key: true
      t.references :journal_entry, index: true, null: false, foreign_key: true
      t.string :currency, null: false
      t.stamps
    end
  end
end
