class ShipmentBookkeeper < ParcelBookkeeper
  private

    def payables_not_billed_account
      :invoice_to_create_clients
    end

    # This method permits to add stock journal entries corresponding to the
    # incoming or outgoing parcels.
    # It depends on the preferences which permit to activate the "permanent stock
    # inventory" and "automatic bookkeeping".
    #
    # | Parcel mode            | Debit                      | Credit                    |
    # | outgoing parcel        | stock_movement (603X/71X)  | stock (3X)                |
    def generate_stock_entry(entry_recorder, amount:, label:, stock_account_id:, movement_account_id:, item:)
      entry_recorder.add_debit label, movement_account_id, amount, resource: item, as: :stock_movement, variant: item.variant
      entry_recorder.add_credit label, stock_account_id, amount, resource: item, as: :stock, variant: item.variant
    end
end
