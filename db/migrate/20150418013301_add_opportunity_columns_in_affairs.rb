class AddOpportunityColumnsInAffairs < ActiveRecord::Migration
  def change
    change_table :affairs do |t|
      t.references :responsible, index: true
      # t.references :affair,      index: true
      # t.references :client,      index: true, null: false
      t.datetime :dead_line_at
      t.string :name
      # t.string     :number
      t.text :description
      t.decimal :pretax_amount, precision: 19, scale: 4, default: 0.0
      # t.string     :currency
      # t.string     :origin => :nature
      t.string :origin
      t.string :type
      t.string :state
      t.decimal :probability_percentage, precision: 19, scale: 4, default: 0.0
      t.string :third_role
      # t.stamps
    end

    add_index :affairs, :name

    change_column_null :affairs, :originator_type, null: true
    change_column_null :affairs, :originator_id, null: true

    reversible do |d|
      d.up do
        execute "UPDATE affairs SET type = CASE WHEN ticket THEN 'SaleTicket' ELSE 'Affair' END"
        execute "UPDATE affairs SET state = 'won'"
        execute "UPDATE affairs SET third_role = 'client'"
        execute "UPDATE affairs SET third_role = 'supplier' WHERE id IN (SELECT affair_id FROM purchases) AND id NOT IN (SELECT affair_id FROM sales)"
      end
      d.down do
        execute "UPDATE affairs SET ticket = TRUE WHERE type = 'SaleTicket'"
        deals = 'SELECT affair_id, originator_type, originator_id, created_at FROM (' + %w[Gap Sale Purchase IncomingPayment OutgoingPayment].collect do |type|
          "(SELECT affair_id, '#{type}' AS originator_type, id AS originator_id, created_at FROM #{type.tableize})"
        end.join(' UNION ALL ') + ') AS deals ORDER BY created_at FETCH FIRST ROW ONLY'
        execute "UPDATE affairs SET originator_id = originators.originator_id, originator_type = originators.originator_type FROM (#{deals}) AS originators WHERE id = originators.affair_id"
      end
    end

    change_column_null :affairs, :third_role, false
    change_column_null :gaps, :affair_id, true

    remove_column :affairs, :ticket, :boolean, null: false, default: false
    remove_reference :affairs, :originator, polymorphic: true, index: true
  end
end
