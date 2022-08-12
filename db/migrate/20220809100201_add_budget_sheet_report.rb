class AddBudgetSheetReport < ActiveRecord::Migration[5.1]

  REPORT = { name: 'Budget prévisionnel', nature: 'planned_budget_sheet' }.freeze

  def up
    execute <<~SQL
      INSERT INTO document_templates (name, active, by_default, nature, language, archiving, managed, created_at, updated_at, file_extension)
      VALUES ('#{REPORT[:name]}', 't', 'f', '#{REPORT[:nature]}', 'fra', 'last', 't', now(), now(), 'odt')
    SQL
  end

  def down
    execute <<~SQL
      DELETE FROM document_templates
      WHERE name = '#{REPORT[:name]}' AND managed = true AND nature = '#{REPORT[:nature]}' AND language = 'fra'
    SQL
  end
end
