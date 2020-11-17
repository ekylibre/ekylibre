class ReceptionBookkeeper < ParcelBookkeeper

  def call
    return unless given?

    # For purchase_not_received or sale_not_emitted
    bookkeep_payables_not_billed if Preference[:unbilled_payables]

    super
  end

  private

    def bookkeep_payables_not_billed
      label = tc(
        :undelivered_invoice,
        resource: resource.class.model_name.human,
        number: number,
        entity: entity.full_name,
        mode: nature.l
      )

      account = Account.find_or_import_from_nomenclature(:suppliers_invoices_not_received)

      # For unbilled payables
      journal = Journal.used_for_unbilled_payables!(currency: currency)
      journal_entry(journal, printed_on: printed_on, as: :undelivered_invoice) do |entry|
        items.each do |item|
          amount = (item.trade_item && item.trade_item.pretax_amount) || item.stock_amount
          next if item.variant.nil? || item.variant.charge_account.nil? || amount.zero?

          entry.add_debit label, account.id, amount, resource: item, as: :unbilled, variant: item.variant
          entry.add_credit label, item.variant.charge_account.id, amount, resource: item, as: :expense, variant: item.variant
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
    def generate_stock_entry(entry_recorder, amount:, label:, stock_account_id:, movement_account_id:, item:)
      entry_recorder.add_debit label, stock_account_id, amount, resource: item, as: :stock, variant: item.variant
      entry_recorder.add_credit label, movement_account_id, amount, resource: item, as: :stock_movement, variant: item.variant
    end
end
