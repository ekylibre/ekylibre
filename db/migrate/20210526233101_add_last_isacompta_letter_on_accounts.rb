class AddLastIsacomptaLetterOnAccounts < ActiveRecord::Migration[5.0]
  def change
    add_column :accounts, :last_isacompta_letter, :jsonb, default: {}
  end
end
