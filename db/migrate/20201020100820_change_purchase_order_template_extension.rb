class ChangePurchaseOrderTemplateExtension < ActiveRecord::Migration
  def change
    execute <<-SQL
      UPDATE document_templates
      SET file_extension = 'odt',
          active = 't',
          by_default = 't'
      WHERE managed = 't'
        AND nature = 'purchases_order';

      UPDATE document_templates
      SET active ='f',
          by_default = 'f'
      WHERE managed = 'f'
        AND nature = 'purchases_order'
    SQL
  end
end
