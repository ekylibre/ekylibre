class MergeContactLine4 < ActiveRecord::Migration
  def self.up
    add_column :contacts, :line_4, :string, :limit=>48

    execute "UPDATE #{quote_table_name(:contacts)} SET line_4 = "+connection.trim(connection.concatenate("COALESCE(line_4_number,'')", "' '", "COALESCE(line_4_street,'')"))

    remove_column :contacts, :line_4_number
    remove_column :contacts, :line_4_street
    remove_column :contacts, :norm_id

    drop_table :address_norms
    drop_table :address_norm_items
  end

  def self.down
    # AddressNorm
    create_table :address_norms do |t|
      t.column :name,                   :string,   :null=>false
      t.column :reference,              :string
      t.column :default,                :boolean,  :null=>false, :default=>false
      t.column :rtl,                    :boolean,  :null=>false, :default=>false
      t.column :align,                  :string,   :null=>false, :default=>"left", :limit=>8
      t.column :company_id,             :integer,  :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :address_norms, :company_id
    add_index :address_norms, [:name, :company_id], :unique=>true

    # AddressNormItem
    create_table :address_norm_items do |t|
      t.column :contact_norm_id,        :integer, :null=>false, :references=>:address_norms,  :on_delete=>:cascade, :on_update=>:cascade
      t.column :name,                   :string,  :null=>false
      t.column :nature,                 :string,  :null=>false, :default=>"content", :limit=>15
      t.column :maxlength,              :integer, :null=>false, :default=>38
      t.column :content,                :string
      t.column :left_nature,            :string,  :limit=>15
      t.column :left_value,             :string,  :limit=>63
      t.column :right_nature,           :string,  :default=>"space", :limit=>15
      t.column :right_value,            :string,  :limit=>63
      t.column :position,               :integer
      t.column :company_id,             :integer, :null=>false, :references=>:companies, :on_delete=>:cascade, :on_update=>:cascade
    end
    add_index :address_norm_items, :company_id
    add_index :address_norm_items, [:nature, :contact_norm_id, :company_id], :unique=>true, :name=>"#{quote_table_name(:address_norm)}_items_nature"
    add_index :address_norm_items, [:name, :contact_norm_id, :company_id],  :unique=>true, :name=>"#{quote_table_name(:address_norm)}_items_name"

    add_column :contacts, :norm_id, :integer
    add_column :contacts, :line_4_number, :string, :limit=>38
    add_column :contacts, :line_4_street, :string, :limit=>38

    execute "UPDATE #{quote_table_name(:contacts)} SET line_4_street = "+connection.substr("line_4", 1, 38)

    remove_column :contacts, :line_4
  end
end
