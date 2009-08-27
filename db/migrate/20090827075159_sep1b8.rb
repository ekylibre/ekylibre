class Sep1b8 < ActiveRecord::Migration
  def self.up
    create_table :print_templates do |t|
      t.column :name,                   :string, :null=>false
      t.column :source,                 :text
      t.column :cache,                  :text
      t.column :country,                :string, :limit=>8
      t.column :language_id,            :integer, :references=>:language
      t.column :company_id,             :integer,  :null=>false, :references=>:companies
    end
    add_index :print_templates, :company_id
    add_index :print_templates, :name

  end

  def self.down
    drop_table :print_templates
  end
end
