class ParcelBookkeeper < Ekylibre::Bookkeeper
  def call
    # This method permits to add stock journal entries corresponding to the
    # incoming or outgoing parcels.
    # It depends on the preferences which permit to activate the "permanent stock
    # inventory" and "automatic bookkeeping".
    #
    # | Parcel mode            | Debit                      | Credit                    |
    # | incoming parcel        | stock (3X)                 | stock_movement (603X/71X) |
    # | outgoing parcel        | stock_movement (603X/71X)  | stock (3X)                |
    # For purchase_not_received or sale_not_emitted
    invoice = lambda do |usage, order|
      lambda do |entry|
        label = tc(:undelivered_invoice,
                   resource: resource.class.model_name.human,
                   number: number, entity: entity.full_name, mode: nature.l)
        account = Account.find_or_import_from_nomenclature(usage)
        items.each do |item|
          amount = (item.trade_item && item.trade_item.pretax_amount) || item.stock_amount
          next unless item.variant && item.variant.charge_account && amount.nonzero?
          if order
            entry.add_credit label, account.id, amount, resource: item, as: :unbilled, variant: item.variant
            entry.add_debit  label, item.variant.charge_account.id, amount, resource: item, as: :expense, variant: item.variant
          else
            entry.add_debit  label, account.id, amount, resource: item, as: :unbilled, variant: item.variant
            entry.add_credit label, item.variant.charge_account.id, amount, resource: item, as: :expense, variant: item.variant
          end
        end
      end
    end

    ufb_accountable = Preference[:unbilled_payables] && given?
    # For unbilled payables
    journal = Journal.used_for_unbilled_payables!(currency: resource.currency)
    journal_entry(journal, printed_on: printed_on, as: :undelivered_invoice, if: ufb_accountable && incoming?, &invoice.call(:suppliers_invoices_not_received, true))

    journal_entry(journal, printed_on: printed_on, as: :undelivered_invoice, if: ufb_accountable && outgoing?, &invoice.call(:invoice_to_create_clients, false))

    accountable = Preference[:permanent_stock_inventory] && given?
    # For permanent stock inventory
    journal = Journal.used_for_permanent_stock_inventory!(currency: resource.currency)
    journal_entry(journal, printed_on: printed_on, if: (Preference[:permanent_stock_inventory] && given?)) do |entry|
      label = tc(:bookkeep, resource: resource.class.model_name.human,
                            number: number, entity: entity.full_name, mode: nature.l)
      items.each do |item|
        variant = item.variant
        next unless variant && variant.storable? && item.stock_amount.nonzero?
        if incoming?
          entry.add_credit(label, variant.stock_movement_account_id, item.stock_amount, resource: item, as: :stock_movement, variant: item.variant)
          entry.add_debit(label, variant.stock_account_id, item.stock_amount, resource: item, as: :stock, variant: item.variant)
        elsif outgoing?
          entry.add_debit(label, variant.stock_movement_account_id, item.stock_amount, resource: item, as: :stock_movement, variant: item.variant)
          entry.add_credit(label, variant.stock_account_id, item.stock_amount, resource: item, as: :stock, variant: item.variant)
        end
      end
    end
  end
end
