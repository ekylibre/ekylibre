class UpdatePurchaseOrderStateAgain < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute "UPDATE purchases SET state = 'opened' WHERE state = 'estimate' AND type = 'PurchaseOrder'"
        execute "UPDATE purchases SET state = 'closed' WHERE state = 'aborted' AND type = 'PurchaseOrder'"
      end
      dir.down do
      end
    end
  end
end
