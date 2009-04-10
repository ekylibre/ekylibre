class Mar2v1 < ActiveRecord::Migration
  
  def self.up
    create_table :professions do |t|
      t.column :name,                   :string, :null=>false
      t.column :code,                   :string
      t.column :rome,                   :string   
      t.column :commercial,             :boolean
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict
    end
    
    add_column :employees, :profession_id, :integer, :references=>:professions, :on_delete=>:restrict, :on_update=>:restrict

    add_column :employees, :commercial, :boolean, :null=>false, :default=>false
    
  end
  
  def self.down
    remove_column :employees, :commercial
    remove_column :employees, :profession_id
    drop_table :professions
  end
  
end
