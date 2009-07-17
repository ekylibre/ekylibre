class Sep1v1 < ActiveRecord::Migration
  def self.up
    create_table :areas do |t|
      t.column :postcode, :string, :null=>false
      t.column :name, :string, :null=>false
      t.column :city_id, :integer, :null=>false, :references=>:cities, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id, :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    
    create_table :cities do |t|
      t.column :insee_cdc, :string, :limit=>1
      t.column :insee_cheflieu, :string, :limit=>1
      t.column :insee_reg, :string, :limit=>2
      t.column :insee_dep, :string, :limit=>3
      t.column :insee_com, :string, :limit=>3
      t.column :insee_ar, :string, :limit=>1
      t.column :insee_ct, :string, :limit=>2
      # Type de nom en clair
      t.column :insee_tncc, :string, :limit=>1
      # Article en majuscule
      t.column :insee_artmaj, :string, :limit=>5
      # Nom en clair (majuscule)
      t.column :insee_ncc, :string, :limit=>70
      # Article (typographie en riche)
      t.column :insee_artmin, :string, :limit=>5
      # Nom en clair (typographie riche)
      t.column :insee_nccenr, :string, :limit=>70
      t.column :name, :string, :null=>false
      t.column :district_id, :integer, :null=>false, :references=>:districts, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id, :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    
    create_table :districts do |t|
      t.column :name, :string, :null=>false
      t.column :company_id, :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    
    add_column :contacts, :area_id, :integer, :null=>false, :references=>:areas, :on_delete=>:cascade, :on_update=>:cascade
  end
  
  
  def self.down
    remove_column :contacts, :area_id    
    drop_table :districts
    drop_table :cities
    drop_table :areas
  end
end
