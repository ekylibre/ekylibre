class AddOriginatorReferenceToInterventionTemplate < ActiveRecord::Migration
  def change
    unless column_exists?(:intervention_templates, :originator_id)
      add_column :intervention_templates, :originator_id, :integer, null: true
    end
  end
end
