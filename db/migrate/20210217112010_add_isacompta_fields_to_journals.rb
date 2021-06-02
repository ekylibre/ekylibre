class AddIsacomptaFieldsToJournals < ActiveRecord::Migration[5.0]
  def change
    add_column :journals, :isacompta_code, :string, limit: 2
    add_column :journals, :isacompta_label, :string, limit: 30
    add_reference :journals, :financial_year_exchange, foreign_key: true
  end
end
