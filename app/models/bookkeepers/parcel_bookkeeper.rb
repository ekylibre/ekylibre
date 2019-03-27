class ParcelBookkeeper < Ekylibre::Bookkeeper
  def call
    return unless given?
    # For purchase_not_received or sale_not_emitted
    bookkeep_payables_not_billed if Preference[:unbilled_payables]
    # For permanent stock inventory
    bookkeep_stock_inventory if Preference[:permanent_stock_inventory]
  end

  private

  def bookkeep_payables_not_billed
    label = tc(:undelivered_invoice,
               resource: resource.class.model_name.human,
               number: number, entity: entity.full_name, mode: nature.l)

    account = Account.find_or_import_from_nomenclature(payables_not_billed_account)

    # For unbilled payables
    journal = Journal.used_for_unbilled_payables!(currency: currency)
    journal_entry(journal, printed_on: printed_on, as: :undelivered_invoice) do |entry|
      items.each do |item|
        amount = (item.trade_item && item.trade_item.pretax_amount) || item.stock_amount
        next unless item.variant && item.variant.charge_account && amount.nonzero?
        accounts = { unbilled: account.id,
                     expense:  item.variant.charge_account.id }


        generate_entry(entry, amount, label: label, from: accounts.to_a.first, to: accounts.to_a.last, item: item)
      end
    end
  end

  # This method permits to add stock journal entries corresponding to the
  # incoming or outgoing parcels.
  # It depends on the preferences which permit to activate the "permanent stock
  # inventory" and "automatic bookkeeping".
  #
  # | Parcel mode            | Debit                      | Credit                    |
  # | incoming parcel        | stock (3X)                 | stock_movement (603X/71X) |
  # | outgoing parcel        | stock_movement (603X/71X)  | stock (3X)                |
  def bookkeep_stock_inventory
    journal = Journal.used_for_permanent_stock_inventory!(currency: resource.currency)
    journal_entry(journal, printed_on: printed_on) do |entry|
      label = tc(:bookkeep, resource: resource.class.model_name.human,
                            number: number, entity: entity.full_name, mode: nature.l)
      items.each do |item|
        variant = item.variant
        next unless variant && variant.storable? && item.stock_amount.nonzero?
        accounts = { stock_movement: variant.stock_account_id,
                     stock: variant.stock_movement_account_id }

        generate_entry entry, item.stock_amount, label: label, from: accounts.to_a.first, to: accounts.to_a.last, item: item
      end
    end
  end

  def generate_entry(entry_recorder, amount, label:, from:, to:, item:)
    from_as, from_account = *from
    to_as,   to_account = *to
    entry_recorder.add_debit  label, from_account, amount, resource: item, as: from_as, variant: item.variant
    entry_recorder.add_credit label,   to_account, amount, resource: item, as:   to_as, variant: item.variant
  end
end
