class ReconfigureCashSessionSequence < ActiveRecord::Migration[4.2]
  def change
    rename_column :cash_sessions, :sequence_id, :number
    change_column :cash_sessions, :number, :string
  end
end
