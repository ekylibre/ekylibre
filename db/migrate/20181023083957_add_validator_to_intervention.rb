class AddValidatorToIntervention < ActiveRecord::Migration[4.2]
  def change
    add_column :interventions, :validator_id, :integer, default: nil
  end
end
