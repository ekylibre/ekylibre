class Serp1t4 < ActiveRecord::Migration
  def self.up

    add_column :entity_link_natures, :propagate_contacts, :boolean, :null=>false, :default=>false
    
    add_column :payments, :scheduled, :boolean, :null=>false,  :default=>false

    add_column :payments, :validated, :boolean, :null=>false,  :default=>true

    add_column :payments, :downpayment, :boolean, :null=>false,  :default=>false

  end

  def self.down
    remove_column :payments, :downpayment
    remove_column :payments, :validated
    remove_column :payments, :scheduled
    remove_column :entity_link_natures, :propagate_contacts
  end
end
