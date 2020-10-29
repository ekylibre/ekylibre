class AddShippingNoteTemplate < ActiveRecord::Migration
  def up
    res = execute "SELECT COUNT(*) FROM document_templates WHERE nature = 'shipping_note' AND managed = 't'"
    if res.to_a.first['count'].to_i.zero?
      execute <<-SQL
      INSERT INTO document_templates(name, active, by_default, nature, language, archiving, managed, created_at, updated_at)
        VALUES ('Bon de livraison', 't', 't', 'shipping_note', 'fra', 'last', 't', now(), now())
      SQL
    end
  end

  def down
    execute <<-SQL
    DELETE FROM document_templates WHERE nature = 'shipping_note' AND managed = 't'
    SQL
  end
end
