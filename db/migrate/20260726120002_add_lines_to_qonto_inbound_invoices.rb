class AddLinesToQontoInboundInvoices < ActiveRecord::Migration[5.2]
  def change
    # Normalized (PA-agnostic) invoice lines, so turning an inbound invoice into
    # a purchase does not need to re-parse the raw Qonto payload.
    add_column :qonto_inbound_invoices, :lines, :jsonb, null: false, default: []
  end
end
