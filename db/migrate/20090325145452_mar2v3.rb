class Mar2v3 < ActiveRecord::Migration
  def self.up
    
    remove_column :bank_accounts, :iban_label2
    change_column :bank_accounts, :iban, :string, :null=>false, :default=>"FR76" , :limit=>27 
    change_column :bank_accounts, :iban_label, :string, :null=>false, :default=>"FR76" , :limit=>48 
    add_column :bank_accounts, :bank_code, :string, :limit=>5
    add_column :bank_accounts, :agency_code, :string, :limit=>5
    add_column :bank_accounts, :number, :string, :limit=>11
    add_column :bank_accounts, :key, :string, :limit=>2
    
    add_column :bank_accounts, :mode, :string, :null=>false, :default=>"IBAN"
       
  end
  
  def self.down
    remove_column :bank_accounts, :mode
    remove_column :bank_accounts, :key
    remove_column :bank_accounts, :number
    remove_column :bank_accounts, :agency_code
    remove_column :bank_accounts, :bank_code
    change_column :bank_accounts, :iban_label, :string, :null=>false, :limit=>48 
    change_column :bank_accounts, :iban, :string,:null=>false, :limit=>30
    add_column :bank_accounts, :iban_label2, :string,  :null=>false, :limit=>48
  end
end
