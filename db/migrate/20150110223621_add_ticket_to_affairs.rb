class AddTicketToAffairs < ActiveRecord::Migration[4.2]
  def change
    add_column :affairs, :ticket, :boolean, null: false, default: false
  end
end
