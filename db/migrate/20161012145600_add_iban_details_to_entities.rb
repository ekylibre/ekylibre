class AddIbanDetailsToEntities < ActiveRecord::Migration[4.2]
  def change
    change_table :entities do |t|
      t.string :bank_account_holder_name
      t.string :bank_identifier_code
      t.string :iban
    end
  end
end
