class PurchaseOrder < Purchase

  state_machine :state, initial: :estimate do
    state :estimate
    state :opened_order
    state :closed_order
    state :aborted
    event :open do
      transition estimate: :opened_order, if: :has_content?
    end
    event :close do
      transition opened_order: :closed_order, if: :items_all_received?
    end
    event :abort do
    	transition estimate: :aborted
    	transition opened_order: :aborted, if: :has_reception? == false
    end
  end

    before_validation(on: :create) do
    self.state = :estimate
  end

  def has_reception?
  	# Return a boolean to check if the order is linked to at least one parcel
  end

  def items_all_received?
  	# Return a boolean to check if the order has all of his items received
  end
end