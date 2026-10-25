class AddKindToQontoInboundInvoices < ActiveRecord::Migration[5.2]
  # What the received document is, because Ekylibre does not treat them as the
  # same object: supplier invoice and expense report become a purchase, card
  # receipt and other documents are only attached to a bank statement line.
  #   invoice | expense | receipt | other
  def up
    add_column :qonto_inbound_invoices, :kind, :string, null: false, default: 'invoice'
    add_index :qonto_inbound_invoices, :kind

    # Existing rows were all imported as invoices; the raw Qonto payload kept
    # the category, so they can be sorted without calling the API again.
    execute <<~SQL
      UPDATE qonto_inbound_invoices
      SET kind = CASE
        WHEN payload->>'source_type' = 'e_invoicing' THEN 'invoice'
        WHEN upper(payload->>'attachment_category') = 'INVOICE' THEN 'invoice'
        WHEN upper(payload->>'attachment_category') = 'EXPENSE_RECEIPT' THEN 'expense'
        WHEN upper(payload->>'attachment_category') = 'CARD_RECEIPT' THEN 'receipt'
        ELSE 'other'
      END
      WHERE payload->>'attachment_category' IS NOT NULL
         OR payload->>'source_type' IS NOT NULL
    SQL
  end

  def down
    remove_index :qonto_inbound_invoices, :kind
    remove_column :qonto_inbound_invoices, :kind
  end
end
