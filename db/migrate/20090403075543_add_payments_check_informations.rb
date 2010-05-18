class AddPaymentsCheckInformations < ActiveRecord::Migration
  def self.up
    add_column :payment_modes, :mode,           :string,  :limit=>5
    add_column :payments,      :bank,           :string
    add_column :payments,      :check_number,   :string
    add_column :payments,      :account_number, :string
  end

  def self.down
    remove_column :payment_modes, :mode
    remove_column :payments,      :bank
    remove_column :payments,      :check_number
    remove_column :payments,      :account_number
  end
end
