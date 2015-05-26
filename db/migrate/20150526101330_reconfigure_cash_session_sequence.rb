class ReconfigureCashSessionSequence < ActiveRecord::Migration
  def change
    rename_column :cash_sessions, :sequence_id, :number
  end
end
