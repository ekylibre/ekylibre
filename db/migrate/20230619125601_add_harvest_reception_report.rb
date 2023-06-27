class AddHarvestReceptionReport < ActiveRecord::Migration[5.2]

  REPORT = { name: 'Réception de récolte', nature: 'harvest_reception' }.freeze

  def up
    if connection.select_value("SELECT count(*) FROM document_templates WHERE nature = '#{REPORT[:nature]}'") == 0
      execute <<~SQL
        INSERT INTO document_templates (name, active, by_default, nature, language, archiving, managed, created_at, updated_at, file_extension)
        VALUES ('#{REPORT[:name]}', 't', 't', '#{REPORT[:nature]}', 'fra', 'last', 't', now(), now(), 'odt')
      SQL
    end
  end

  def down
    if connection.select_value("SELECT count(*) FROM document_templates WHERE nature = '#{REPORT[:nature]}'") > 0
      execute <<~SQL
        DELETE FROM document_templates
        WHERE name = '#{REPORT[:name]}' AND managed = true AND nature = '#{REPORT[:nature]}' AND language = 'fra'
      SQL
    end
  end
end
