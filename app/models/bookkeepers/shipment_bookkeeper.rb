class ShipmentBookkeeper < ParcelBookkeeper
  private

    def payables_not_billed_account
      :invoice_to_create_clients
    end

    def generate_entry(entry_recorder, amount, label:, from:, to:, item:)
      from, to = to, from
      super
    end
end
