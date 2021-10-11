class DocumentTemplateTranslation < ActiveRecord::Migration[5.0]
  def change
    execute "UPDATE document_templates SET name='Coûts de production détaillés' WHERE name='Coût de production détaillé'"
    execute "UPDATE document_templates SET name='Grand-livre' WHERE name='Grand livre'"
  end
end
