class NormalizeTradeAffairs < ActiveRecord::Migration
  def change
    add_column :affairs, :letter, :string

    reversible do |d|
      d.up do
        execute "UPDATE affairs SET third_role = 'client' WHERE third_role != 'client' AND (id IN (SELECT affair_id FROM sales) OR id IN (SELECT affair_id FROM incoming_payments)) AND NOT (id IN (SELECT affair_id FROM purchases) OR id IN (SELECT affair_id FROM outgoing_payments))"
        execute "UPDATE affairs SET third_role = 'supplier' WHERE third_role != 'supplier' AND NOT (id IN (SELECT affair_id FROM sales) OR id IN (SELECT affair_id FROM incoming_payments)) AND (id IN (SELECT affair_id FROM purchases) OR id IN (SELECT affair_id FROM outgoing_payments))"
        execute "UPDATE affairs SET type = 'SaleAffair' WHERE third_role = 'client'"
        execute "UPDATE affairs SET type = 'PurchaseAffair' WHERE third_role = 'supplier'"
      end
      d.down do
        execute "UPDATE affairs SET third_role = CASE WHEN type = 'SaleAffair' THEN 'client' ELSE 'supplier' END"
        execute "UPDATE affairs SET type = 'Affair' WHERE type IN ('SaleAffair', 'PurchaseAffair')"
      end
    end

    revert { add_column :affairs, :third_role, :string }

    add_column :gaps, :type, :string

    reversible do |d|
      d.up do
        execute "UPDATE gaps SET type = CASE WHEN entity_role = 'client' THEN 'SaleGap' ELSE 'PurchaseGap' END"
        # Sets losses as negative value
        execute "UPDATE gaps SET amount = -amount, pretax_amount = -pretax_amount WHERE direction = 'loss'"
        execute "UPDATE gap_items AS gi SET amount = -gi.amount, pretax_amount = -gi.pretax_amount FROM gaps AS g WHERE g.id = gap_id AND g.direction = 'loss'"
      end
      d.down do
        # Sets losses as positive value
        execute "UPDATE gaps SET amount = -amount, pretax_amount = -pretax_amount WHERE direction = 'loss'"
        execute "UPDATE gap_items AS gi SET amount = -gi.amount, pretax_amount = -gi.pretax_amount FROM gaps AS g WHERE g.id = gap_id AND g.direction = 'loss'"
        # Re-set entity_role
        execute "UPDATE gaps SET entity_role = CASE WHEN type = 'SaleGap' THEN 'client' ELSE 'supplier' END"
        change_column_null :gaps, :entity_role, false
      end
    end

    revert do
      add_column :gaps, :entity_role, :string
    end
  end
end
