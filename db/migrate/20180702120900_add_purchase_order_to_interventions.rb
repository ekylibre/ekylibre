class AddPurchaseOrderToInterventions < ActiveRecord::Migration[4.2]
  def change
    unless column_exists? :interventions, :purchase_id
      add_reference :interventions, :purchase, index: true, foreign_key: true
    end
  end
end
