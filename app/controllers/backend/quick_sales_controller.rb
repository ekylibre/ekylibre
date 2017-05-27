module Backend
  class QuickSalesController < QuickAffairsController
    Trade   = Sale
    Payment = IncomingPayment

    def new
      super
    end

    def create
      super
    end
  end
end
