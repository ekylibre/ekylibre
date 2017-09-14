class AddPurchaseOrderToInterventions < ActiveRecord::Migration
  def change
    add_reference :interventions, :purchase, index: true, foreign_key: true
  end
end
