class ParcelBookkeeper < Ekylibre::Bookkeeper
  def call
    return unless given?

    # For permanent stock inventory
    bookkeep_stock_inventory if Preference[:permanent_stock_inventory]
  end

  private

    def bookkeep_stock_inventory
      journal = Journal.used_for_permanent_stock_inventory!(currency: resource.currency)

      journal_entry(journal, printed_on: printed_on) do |entry|
        label = tc(:bookkeep, resource: resource.class.model_name.human, number: number, entity: entity.full_name, mode: nature.l)

        items.each do |item|
          variant = item.variant
          next if variant.nil? || !variant.storable? || item.stock_amount.zero?

          generate_stock_entry(
            entry,
            amount: item.stock_amount,
            label: label,
            stock_account_id: variant.stock_account_id,
            movement_account_id: variant.stock_movement_account_id,
            item: item
          )
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
    def generate_stock_entry(entry_recorder, amount:, label:, stock_account_id:, movement_account_id:, item:)
      raise NotImplementedError.new('Should be implemented in subclasses')
    end
end
