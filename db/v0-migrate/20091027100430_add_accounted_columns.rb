class AddAccountedColumns < ActiveRecord::Migration
  def self.up
    add_column :entries, :draft, :boolean, :null=>false, :default=>false

    [:invoices, :sale_orders, :payments, :purchase_orders, :transfers].each do |model|
      add_column model, :accounted, :boolean, :null=>false, :default=>false
    end

  end

  def self.down

    [:invoices, :sale_orders, :payments, :purchase_orders, :transfers].each do |model|
      remove_column model, :accounted
    end

    remove_column :entries, :draft


  end
end
