class GlobalCurrency
  def initialize(currency)
    @currency = currency
  end

  def convert_to(new_currency, rate: 1)
    ActiveRecord::Base.transaction do
      # JournalEntryItem
      JournalEntryItem.update_all("absolute_debit = #{rate} * absolute_debit, absolute_credit = #{rate} * absolute_credit, absolute_currency = '#{new_currency}', absolute_pretax_amount = #{rate} * absolute_pretax_amount")
      # JournalEntry
      JournalEntry.update_all("absolute_debit = #{rate} * absolute_debit, absolute_credit = #{rate} * absolute_credit, absolute_currency = '#{new_currency}'")

      # In the future: Sale & Purchase and optional catalogs...
    end
    @currency = new_currency
  end
end
