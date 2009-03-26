class Mar2v3 < ActiveRecord::Migration
  def self.up
    
    add_column :bank_accounts, :bank_code, :string, :limit=>5
    add_column :bank_accounts, :agency_code, :string, :limit=>5
    add_column :bank_accounts, :number, :string, :limit=>11
    add_column :bank_accounts, :key, :string, :limit=>2
    
    add_column :bank_accounts, :mod, :string, :null=>false, :default=>"IBAN"
       
  end

  def self.down
    remove_column :bank_accounts, :mod
    remove_column :bank_accounts, :key
    remove_column :bank_accounts, :number
    remove_column :bank_accounts, :agency_code
    remove_column :bank_accounts, :bank_code
  end
end
