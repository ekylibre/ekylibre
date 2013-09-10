class AddClientInformations < ActiveRecord::Migration
  def self.up
    add_column :entities, :proposer_id, :integer, :references=>:entities
    add_column :entities, :payment_mode_id, :integer, :references=>:payment_modes
    add_column :entities, :payment_delay_id, :integer, :references=>:delays
    add_column :entities, :invoices_count, :integer
  end

  def self.down
    remove_column :entities, :invoices_count
    remove_column :entities, :payment_delay_id
    remove_column :entities, :payment_mode_id
    remove_column :entities, :proposer_id
  end
end
