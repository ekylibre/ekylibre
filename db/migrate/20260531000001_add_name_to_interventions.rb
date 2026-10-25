class AddNameToInterventions < ActiveRecord::Migration[5.2]
  def change
    add_column :interventions, :name, :string
  end
end
