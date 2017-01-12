module Backend
  class QuickPurchasesController < QuickAffairsController
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
