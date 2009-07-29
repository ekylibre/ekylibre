class Sep1v2 < ActiveRecord::Migration
  def self.up
   create_table :mandates do |t|
      t.column :started_on, :date, :null=>false
      t.column :stopped_on, :date, :null=>false
      t.column :family, :string, :null=>false
      t.column :organization, :string, :null=>false
      t.column :title, :string, :null=>false
      t.column :entity_id, :integer, :null=>false, :references=>:entities, :on_delete=>:cascade, :on_update=>:cascade
      t.column :company_id, :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end

    add_index :mandates, [:family, :company_id]
    add_index :mandates, [:organization, :company_id]
    add_index :mandates, [:title, :company_id]

  end

  def self.down
    remove_index :mandates,[:family, :company_id]
    remove_index :mandates,[:organization, :company_id]
    remove_index :mandates,[:title, :company_id]
    drop_table :mandates

  end
end
