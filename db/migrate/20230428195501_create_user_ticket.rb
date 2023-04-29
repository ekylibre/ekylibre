class CreateUserTicket < ActiveRecord::Migration[5.2]
  def change
    create_table :user_tickets do |t|
      t.date :used_on, index: true
      t.string :user_email, index: true
      t.string :agent_email, index: true
      t.integer :ticket_quantity, null: false
      t.string :name, index: true
      t.text :description
      t.jsonb :provider, default: {}
      t.stamps
    end
  end
end
