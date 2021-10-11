class RenamePurchaseDocumentNature < ActiveRecord::Migration[4.2]
  def up
    execute "UPDATE document_templates SET nature='purchases_invoice' WHERE nature='purchase'"
  end
  def down
    execute "UPDATE document_templates SET nature='purchase' WHERE nature='purchases_invoice'"
  end
end
