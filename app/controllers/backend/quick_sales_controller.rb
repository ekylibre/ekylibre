module Backend
  class QuickSalesController < QuickAffairsController
    Trade   = Purchase
    Payment = OutgoingPayment

    def new
      super
    end

    def create
      super
    end
  end
end
