class PurchaseInvoice < Purchase
	belongs_to :journal_entry, dependent: :destroy
  belongs_to :undelivered_invoice_journal_entry, class_name: 'JournalEntry', dependent: :destroy
  belongs_to :quantity_gap_on_invoice_journal_entry, class_name: 'JournalEntry', dependent: :destroy
  has_many :journal_entries, as: :resource

  acts_as_affairable :supplier

  scope :invoiced_between, lambda { |started_at, stopped_at|
    where(invoiced_at: started_at..stopped_at)
  }
  scope :unpaid, -> { where(state: %w[order invoice]).where.not(affair: Affair.closeds) }
  scope :current, -> { unpaid }
  scope :current_or_self, ->(purchase) { where(unpaid).or(where(id: (purchase.is_a?(Purchase) ? purchase.id : purchase))) }

  before_validation(on: :create) do
    self.state = :invoice
  end

  validate do
    if invoiced_at
      errors.add(:invoiced_at, :before, restriction: Time.zone.now.l) if invoiced_at > Time.zone.now
    end
  end

  after_update do
    affair.reload_gaps if affair
    true
  end
  
  # This callback permits to add journal entries corresponding to the purchase order/invoice
  # It depends on the preference which permit to activate the "automatic bookkeeping"
  bookkeep do |b|
    b.journal_entry(nature.journal, printed_on: invoiced_on, if: (with_accounting && invoice? && items.any?)) do |entry|
      label = tc(:bookkeep, resource: self.class.model_name.human, number: number, supplier: supplier.full_name, products: (description.blank? ? items.collect(&:name).to_sentence : description))
      items.each do |item|
        entry.add_debit(label, item.account, item.pretax_amount, activity_budget: item.activity_budget, team: item.team, as: :item_product, resource: item, variant: item.variant)
        tax = item.tax
        account_id = item.fixed? ? tax.fixed_asset_deduction_account_id : nil
        account_id ||= tax.deduction_account_id # TODO: Check if it is good to do that
        if tax.intracommunity
          reverse_charge_amount = tax.compute(item.pretax_amount, intracommunity: true).round(precision)
          entry.add_debit(label, account_id, reverse_charge_amount, tax: tax, pretax_amount: item.pretax_amount, as: :item_tax, resource: item, variant: item.variant)
          entry.add_credit(label, tax.intracommunity_payable_account_id, reverse_charge_amount, tax: tax, pretax_amount: item.pretax_amount, resource: item, as: :item_tax_reverse_charge, variant: item.variant)
        else
          entry.add_debit(label, account_id, item.taxes_amount, tax: tax, pretax_amount: item.pretax_amount, as: :item_tax, resource: item, variant: item.variant)
        end
      end
      entry.add_credit(label, supplier.account(nature.payslip? ? :employee : :supplier).id, amount, as: :supplier)
    end

    # For undelivered invoice
    # exchange undelivered invoice from parcel
    journal = unsuppress { Journal.used_for_unbilled_payables!(currency: currency) }
    b.journal_entry(journal, printed_on: invoiced_on, as: :undelivered_invoice, if: (with_accounting && invoice?)) do |entry|
      parcels.each do |parcel|
        next unless parcel.undelivered_invoice_journal_entry
        label = tc(:exchange_undelivered_invoice, resource: parcel.class.model_name.human, number: parcel.number, entity: supplier.full_name, mode: parcel.nature.l)
        undelivered_items = parcel.undelivered_invoice_journal_entry.items
        undelivered_items.each do |undelivered_item|
          next unless undelivered_item.real_balance.nonzero?
          entry.add_credit(label, undelivered_item.account.id, undelivered_item.real_balance, resource: undelivered_item, as: :undelivered_item, variant: undelivered_item.variant)
        end
      end
    end

    # For gap between parcel item quantity and purchase item quantity
    # if more quantity on purchase than parcel then i have value in D of stock account
    journal = unsuppress { Journal.used_for_permanent_stock_inventory!(currency: currency) }
    b.journal_entry(journal, printed_on: invoiced_on, as: :quantity_gap_on_invoice, if: (with_accounting && invoice? && items.any?)) do |entry|
      label = tc(:quantity_gap_on_invoice, resource: self.class.model_name.human, number: number, entity: supplier.full_name)
      items.each do |item|
        next unless item.variant.storable?
        parcel_items_quantity = item.parcel_items.map(&:population).compact.sum
        gap = item.quantity - parcel_items_quantity
        next unless item.parcel_items.any? && item.parcel_items.first.unit_pretax_stock_amount
        quantity = item.parcel_items.first.unit_pretax_stock_amount
        gap_value = gap * quantity
        next if gap_value.zero?
        entry.add_debit(label, item.variant.stock_account_id, gap_value, resource: item, as: :stock, variant: item.variant)
        entry.add_credit(label, item.variant.stock_movement_account_id, gap_value, resource: item, as: :stock_movement, variant: item.variant)
      end
    end
  end

  def self.affair_class
    "#{name}Affair".constantize
  end

  def invoiced_on
    dealt_at.to_date
  end

  def dealt_at
    (invoice? ? invoiced_at : created_at? ? self.created_at : Time.zone.now)
  end

  # Save the last date when the invoice of purchase was received
  def invoice(invoiced_at = nil)
    return false unless can_invoice?
    reload
    self.invoiced_at ||= invoiced_at || Time.zone.now
    save!
    items.each(&:update_fixed_asset)
    super
  end

  def status
    return affair.status if invoice?
    :stop
  end

end