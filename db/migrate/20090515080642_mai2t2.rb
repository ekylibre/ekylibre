class Mai2t2 < ActiveRecord::Migration
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

    
    execute "INSERT INTO entity_categories(company_id, name, created_at, updated_at) SELECT companies.id, 'Par défaut', current_timestamp, current_timestamp FROM companies"

    execute "UPDATE entities SET category_id = c.id FROM entity_categories c WHERE c.name = 'Par défaut' AND c.company_id = entities.company_id"

    add_column :taxes,    :deleted, :boolean, :null=>false, :default=>false
      
    remove_column :taxes, :group_name

    add_column :prices,  :category_id, :integer, :references=>:entity_categories, :on_update=>:restrict, :on_delete=>:restrict

    execute "UPDATE prices SET category_id = c.id FROM entity_categories c WHERE c.name = 'Par défaut' AND c.company_id = prices.company_id"
    

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
