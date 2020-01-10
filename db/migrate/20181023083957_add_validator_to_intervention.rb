class AddValidatorToIntervention < ActiveRecord::Migration
  def change
    add_column :interventions, :validator_id, :integer, default: nil
  end
end
