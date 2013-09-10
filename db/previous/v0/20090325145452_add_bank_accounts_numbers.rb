class AddBankAccountsNumbers < ActiveRecord::Migration
  def self.up

    remove_column :bank_accounts, :iban_label2

    add_column :bank_accounts, :bank_code, :string
    add_column :bank_accounts, :agency_code, :string
    add_column :bank_accounts, :number, :string
    add_column :bank_accounts, :key, :string

    add_column :bank_accounts, :mode, :string, :null=>false, :default=>"IBAN"

  end

  def self.down
    remove_column :bank_accounts, :mode
    remove_column :bank_accounts, :key
    remove_column :bank_accounts, :number
    remove_column :bank_accounts, :agency_code
    remove_column :bank_accounts, :bank_code

    add_column :bank_accounts, :iban_label2, :string,  :null=>false, :limit=>48, :default=>"XXYY0123456789"
  end
end
