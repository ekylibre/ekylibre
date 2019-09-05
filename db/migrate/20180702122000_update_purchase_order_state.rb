class UpdatePurchaseOrderState < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute "UPDATE purchases SET state = 'estimate' WHERE state = 'draft' AND type = 'PurchaseOrder'"
        execute "UPDATE purchases SET state = 'opened' WHERE state = 'order' AND type = 'PurchaseOrder'"
        execute "UPDATE purchases SET state = 'aborted' WHERE state IN ('closed', 'refused') AND type = 'PurchaseOrder'"
      end
      dir.down do
      end
    end
  end
end
