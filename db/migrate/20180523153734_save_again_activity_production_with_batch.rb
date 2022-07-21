class SaveAgainActivityProductionWithBatch < ActiveRecord::Migration[4.2]
  def change
    unless column_exists?(:intervention_proposals, :batch_number)
      add_column :intervention_proposals, :batch_number, :integer
    end

    unless column_exists?(:intervention_proposals, :activity_production_irregular_batch_id)
      add_reference :intervention_proposals, :activity_production_irregular_batch, index: { name: :intervention_proposal_activity_production_irregular_batch_id }, foreign_key: true
    end
  end
end
