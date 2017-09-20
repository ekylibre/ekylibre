module Backend
  module PayslipPaymentsHelper

    def payslip_payments_max_payment
      PayslipPayment.maximum(:amount)
    end

    def payslip_payments_min_amount
      PayslipPayment.minimum(:amount)
    end
  end
end
