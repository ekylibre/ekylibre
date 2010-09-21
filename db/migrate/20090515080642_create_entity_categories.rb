class CreateEntityCategories < ActiveRecord::Migration
  def self.up
    add_column :sale_order_lines, :price_amount, :decimal, :precision=>16, :scale=>2
    add_column :sale_order_lines, :tax_id,       :integer, :references=>:taxes, :on_update=>:restrict, :on_delete=>:restrict 
    add_column :payments,   :entity_id,  :integer,  :references=>:entities,  :on_update=>:restrict,  :on_delete=>:restrict
    add_column :users,  :free_price,  :boolean, :null=>false, :default=>true
    add_column :users,  :reduction_percent,  :decimal, :null=>false, :default=>5

    create_table :entity_categories do |t|
      t.column :name, :string, :null=>false
      t.column :description, :text
      t.column :default, :boolean, :null=>false, :default=>false
      t.column :deleted, :boolean, :null=>false, :default=>false
      t.column :company_id,  :integer,  :null=>false, :references=>:companies, :on_delete=>:restrict, :on_update=>:restrict
    end

    add_column :entities, :category_id, :integer, :references=>:entities, :on_update=>:restrict, :on_delete=>:restrict
    
    execute "INSERT INTO #{quote_table_name(:entity_categories)} (company_id, name, created_at, updated_at) SELECT companies.id, 'Par défaut', current_timestamp, current_timestamp FROM #{quote_table_name(:companies)} AS companies"

    add_column :taxes,    :deleted, :boolean, :null=>false, :default=>false
    remove_index :taxes, :column=>[:group_name, :company_id]
    remove_column :taxes, :group_name

    add_column :prices,  :category_id, :integer, :references=>:entity_categories, :on_update=>:restrict, :on_delete=>:restrict

    categories = connection.select_all("SELECT * FROM #{quote_table_name(:entity_categories)}")
    if categories.size > 0
      categories = "CASE "+categories.collect{|c| "WHEN company_id=#{c['company_id']} THEN #{c['id']}"}.join(" ")+" ELSE 0 END"
      execute "UPDATE #{quote_table_name(:entities)} SET category_id = "+categories 
      execute "UPDATE #{quote_table_name(:prices)} SET category_id = "+categories 
    end
  end  

  def self.down
    remove_column :prices, :category_id
    add_column :taxes, :group_name, :string
    remove_column :taxes, :deleted
    remove_column :entities, :category_id
    drop_table :entity_categories
    remove_column :users, :free_price
    remove_column :users, :reduction_percent
    remove_column :payments, :entity_id
    remove_column :sale_order_lines, :tax_id
    remove_column :sale_order_lines, :price_amount    
  end

end
