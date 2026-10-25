class CreateQontoInboundInvoices < ActiveRecord::Migration[5.2]
  def change
    create_table :qonto_inbound_invoices do |t|
      t.string   :remote_id, null: false
      t.string   :status, null: false, default: 'to_review' # to_review | matched | ignored
      t.string   :supplier_name
      t.string   :supplier_siret
      t.string   :invoice_number
      t.string   :currency
      t.decimal  :amount, precision: 19, scale: 4
      t.decimal  :pretax_amount, precision: 19, scale: 4
      t.date     :issued_on
      t.date     :due_on
      t.references :entity,   foreign_key: true, index: true   # supplier guessed by SIRET
      t.references :purchase, foreign_key: true, index: true   # purchase created from it
      t.references :document, foreign_key: true, index: true   # PDF / Factur-X
      t.jsonb    :payload, null: false, default: {}            # raw, for replayability
      t.timestamps null: false
    end
    add_index :qonto_inbound_invoices, :remote_id, unique: true
    add_index :qonto_inbound_invoices, :status
  end
end
