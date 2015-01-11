class AddTicketToAffairs < ActiveRecord::Migration
  def change
    add_column :affairs, :ticket, :boolean, null: false, default: false
  end
end
