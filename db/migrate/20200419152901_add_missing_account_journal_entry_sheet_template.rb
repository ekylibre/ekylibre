class AddMissingAccountJournalEntrySheetTemplate < ActiveRecord::Migration

  NATURES = { account_journal_entry_sheet: 'Extrait de compte' }

  def up
    values = NATURES.map do |nature, translation|
      res = execute "SELECT COUNT(*) FROM document_templates WHERE nature = '#{nature}' AND managed = 't'"
      next unless res.to_a.first['count'].to_i.zero?
      <<-VALUE
        (#{quote(translation)}, 't', 't', #{quote(nature)}, 'fra', 'last', 't', 'odt', '', now(), now())
      VALUE
    end.compact

    return if values.empty?

    execute <<-SQL
      INSERT INTO document_templates(name, active, by_default, nature, language, archiving, managed, file_extension, formats, created_at, updated_at)
        VALUES
          #{values.join(',')}
    SQL
  end

  def down
    # NOOP
  end

  private

    def quote(value)
      ActiveRecord::Base.connection.quote value
    end
end
