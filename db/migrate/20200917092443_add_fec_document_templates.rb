class AddFecDocumentTemplates < ActiveRecord::Migration[4.2]

    NATURES = { fec_data_error: "Fichier d'erreurs de données FEC",
                fec_structure_error: "Fichier d'erreurs de structure FEC" }

  def up
    NATURES.map do |nature, translation|
      execute <<-SQL
        INSERT INTO document_templates(name, active, by_default, nature, language, archiving, managed, created_at, updated_at)
          VALUES
           (#{quote(translation)}, 't', 't', #{quote(nature)}, 'fra', 'last', 't', now(), now())
        SQL
    end
  end

  def down
    # NOOP
  end

  private

    def quote(value)
      ActiveRecord::Base.connection.quote value
    end
end
