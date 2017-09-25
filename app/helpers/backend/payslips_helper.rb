module Backend
  module PayslipsHelper

    def payslip_max_amount
      Payslip.maximum(:amount)
    end

    def payslip_min_amount
      Payslip.minimum(:amount)
    end
  end
end
