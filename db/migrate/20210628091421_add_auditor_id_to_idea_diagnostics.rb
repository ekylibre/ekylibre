class AddAuditorIdToIdeaDiagnostics < ActiveRecord::Migration[5.0]
  def change
    add_reference :idea_diagnostics, :auditor, foreign_key: { to_table: :entities }
    add_column :idea_diagnostics, :stopped_at, :datetime
  end
end
