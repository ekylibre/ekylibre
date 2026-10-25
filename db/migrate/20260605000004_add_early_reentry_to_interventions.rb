class AddEarlyReentryToInterventions < ActiveRecord::Migration[5.2]
  def change
    add_column :interventions, :early_reentry, :boolean, null: false, default: false
    add_column :interventions, :early_reentry_ppe_description, :text
    add_column :interventions, :early_reentry_reason, :text
  end
end
