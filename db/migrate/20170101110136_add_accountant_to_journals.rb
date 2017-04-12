class AddAccountantToJournals < ActiveRecord::Migration
  def change
    change_table :journals do |t|
      t.references :accountant, index: true
    end
    add_foreign_key :journals, :entities, column: :accountant_id

    change_table :financial_years do |t|
      t.references :accountant, index: true
    end
    add_foreign_key :financial_years, :entities, column: :accountant_id

    create_table :financial_year_exchanges do |t|
      t.references :financial_year, null: false, index: true, foreign_key: { on_delete: :cascade, on_update: :cascade }
      t.date :started_on, null: false
      t.date :stopped_on, null: false
      t.datetime :closed_at
      t.string :public_token
      t.datetime :public_token_expired_at
      t.attachment :import_file
      t.stamps
      t.index :public_token, unique: true
    end

    add_reference :journal_entries, :financial_year_exchange, index: true, foreign_key: { on_delete: :nullify, on_update: :cascade }
  end
end
