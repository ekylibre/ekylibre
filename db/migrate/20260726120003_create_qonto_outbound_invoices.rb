class CreateQontoOutboundInvoices < ActiveRecord::Migration[5.2]
  def change
    create_table :qonto_outbound_invoices do |t|
      t.references :sale, foreign_key: true, index: { unique: true }
      t.string   :remote_id                                   # client_invoice_id at Qonto (set after submit)
      t.string   :status, null: false, default: 'pending'     # pending|submitted|issued|received|failed
      t.string   :remote_status                               # raw einvoicing_status
      t.jsonb    :lifecycle_events, null: false, default: []  # timestamped mirror
      t.jsonb    :last_error, null: false, default: {}         # { code:, detail:, at: }
      t.datetime :submitted_at
      t.datetime :issued_at
      t.datetime :received_at
      t.datetime :last_polled_at
      t.integer  :poll_attempts, null: false, default: 0
      t.timestamps null: false
    end
    # Nullable but unique: many rows may sit remote_id-less (pending) — Postgres
    # allows multiple NULLs in a unique index.
    add_index :qonto_outbound_invoices, :remote_id, unique: true
    add_index :qonto_outbound_invoices, :status
  end
end
