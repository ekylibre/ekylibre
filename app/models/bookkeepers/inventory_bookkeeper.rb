class InventoryBookkeeper < Ekylibre::Bookkeeper
  class NegativeStockValueError < StandardError
    attr_reader :account, :start, :stop, :amount

    def initialize(account, start, stop, amount)
      @account = account
      @start = start
      @stop = stop
      @amount = amount
    end

    def message
      "Found negative stock value (#{amount.to_f}) in account #{account.name} for the period #{start} - #{stop}"
    end
  end

  #          Mode Inventory     |     Debit                      |            Credit            |
  #     physical inventory      |    stock(3X)                   |   stock_movement(603X/71X)   |
  def call
    return if disable_accountancy || recorder.action == :destroy

    journal_entry(journal, printed_on: achieved_at.to_date, if: (financial_year && reflected?)) do |entry|
      fy_started_at = financial_year.started_on.to_time

      # get all variants corresponding to current items
      item_variants.each do |variant|
        # for all items of current variant (if storable)
        # TODO: Put this as constraint in `inventory_variants`
        next unless variant.storable? && variant.stock_account && variant.stock_movement_account

        s = variant.stock_account
        sm = variant.stock_movement_account

        # get balance value of stock account for current fy (from fy started to inventory achieved at)
        current_stock_amount = s.journal_entry_items_calculate(:balance, fy_started_at, achieved_at, except: [resource.journal_entry_id].compact)

        # step 2 : record inventory stock in stock journal
        # TODO update methods to evaluates price stock or open unit_pretax-
        # stock_amount field to the user during inventory
        # build the global value of the stock for each item
        inventoried_stock_amount = items.of_variant(variant).map(&:actual_pretax_stock_amount).compact.sum

        # bookkeep step 2
        stock_movement_amount = if current_stock_amount.zero?
                                  inventoried_stock_amount
                                elsif current_stock_amount > 0.0 && inventoried_stock_amount > 0.0
                                  inventoried_stock_amount - current_stock_amount
                                else
                                  raise NegativeStockValueError.new(s, fy_started_at, achieved_at, current_stock_amount)
                                end

        label = tc(:bookkeep, resource: Inventory.model_name.human, number: number)
        entry.add_credit(label, sm.id, stock_movement_amount, resource: variant, as: :stock, variant: variant)
        entry.add_debit(label, s.id, stock_movement_amount, resource: variant, as: :stock_movement, variant: variant)
      end
    end
  end
end
