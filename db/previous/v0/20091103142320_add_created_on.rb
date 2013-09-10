class AddCreatedOn < ActiveRecord::Migration
  def self.up

    add_column :purchase_orders, :created_on, :date
    add_column :transfers, :created_on, :date
    add_column :payments, :created_on, :date

    for table in [:purchase_orders, :transfers, :payments]
      if connection.adapter_name.lower == "sqlserver"
        execute "UPDATE #{quoted_table_name(table)} SET created_on = created_at WHERE created_on IS NULL"
      else
        execute "UPDATE #{quoted_table_name(table)} SET created_on = CAST(created_at AS date) WHERE created_on IS NULL"
      end
    end

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
