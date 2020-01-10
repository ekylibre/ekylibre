class AddProjectBudgetAndEquipmentToJournalEntriesItems < ActiveRecord::Migration
  def up
    purchase_invoices = PurchaseInvoice
                        .where(id: PurchaseItem.where('equipment_id IS NOT NULL OR project_budget_id IS NOT NULL').map(&:purchase_id).uniq)
                        .uniq

    purchase_invoices.each do |purchase_invoice|
      purchase_invoice_items = purchase_invoice
                               .items
                               .where('equipment_id IS NOT NULL OR project_budget_id IS NOT NULL')

      purchase_invoice_items.each do |purchase_invoice_item|
        journal_entry_item = JournalEntryItem
                             .find_by(resource_id: purchase_invoice_item.id)

        next if journal_entry_item.nil?

        journal_entry_item.update_attributes(equipment_id: purchase_invoice_item.equipment_id,
                                             project_budget_id: purchase_invoice_item.project_budget_id)
      end
    end
  end

  def down; end
end
