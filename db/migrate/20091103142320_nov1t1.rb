class Nov1t1 < ActiveRecord::Migration
  def self.up

    add_column :purchase_orders, :created_on, :date
    add_column :transfers, :created_on, :date
    add_column :payments, :created_on, :date
    
    execute "UPDATE purchase_orders SET created_on = CAST(created_at AS date) WHERE created_on IS NULL "
    execute "UPDATE transfers SET created_on = CAST(created_at AS date) WHERE created_on IS NULL "
    execute "UPDATE payments SET created_on = CAST(created_at AS date) WHERE created_on IS NULL "

    add_column :document_templates, :default, :boolean, :null=>false, :default=>true
    add_column :document_templates, :nature, :string, :limit=>20

    remove_column :purchase_orders, :invoiced

  end

  def self.down
    
    add_column :purchase_orders, :invoiced, :boolean, :null=>false, :default=>false
    remove_column :document_templates, :nature
    remove_column :document_templates, :default
    remove_column :payments, :created_on
    remove_column :transfers, :created_on
    remove_column :purchase_orders, :created_on

  end
end
