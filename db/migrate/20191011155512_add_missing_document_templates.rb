class AddMissingDocumentTemplates < ActiveRecord::Migration

  NATURES = { general_journal: 'Journal centralisateur',
              journal_ledger: 'Etat du journal',
              trial_balance: 'Balance comptable',
              balance_sheet: 'Bilan comptable',
              fixed_asset_registry: 'Etat des immobilisations',
              by_account_fixed_asset_registry: 'Etat des immobilisations par compte',
              gain_and_loss_fixed_asset_registry: 'Etat des plus et moins values',
              pending_vat_register: 'Etat de TVA préparatoire',
              short_balance_sheet: 'Bilan comptable simplifié' }

  def up
    values = NATURES.map do |nature, translation|
      res = execute "SELECT COUNT(*) FROM document_templates WHERE nature = '#{nature}' AND managed = 't'"
      next unless res.to_a.first['count'].to_i.zero?
      <<-VALUE
        (#{quote(translation)}, 't', 't', #{quote(nature)}, 'fra', 'last', 't', now(), now())
      VALUE
    end.compact

    return if values.empty?

    execute <<-SQL
      INSERT INTO document_templates(name, active, by_default, nature, language, archiving, managed, created_at, updated_at)
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
