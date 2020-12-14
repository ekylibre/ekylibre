class AddPurchaseOrdersDocumentTemplate < ActiveRecord::Migration
  def change
    res = execute "SELECT COUNT(*) FROM document_templates WHERE nature = 'purchases_order' AND managed = 't'"
    return unless res.to_a.first['count'].to_i.zero?

    execute <<-SQL
      UPDATE document_templates
        SET active = 'f',
            by_default = 'f'
      WHERE nature = 'purchases_order';

      INSERT INTO document_templates(name, active, by_default, nature, language, archiving, managed, file_extension, created_at, updated_at)
        VALUES ('Bon de commande', 't', 't', 'purchases_order', 'fra', 'last', 't', 'odt', now(), now())
    SQL
  end
end
