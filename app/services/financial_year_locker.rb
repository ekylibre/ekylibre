class FinancialYearLocker

  # @param [FinancialYear] year
  def lock!(year)
    ActiveRecord::Base.transaction do
      get_depreciations_to_lock(year).update_all(locked: true)
      get_loan_repayments_to_lock(year).update_all(locked: true)

      year.update!(state: 'locked')
    end
  end

  private

    def get_depreciations_to_lock(year)
      FixedAssetDepreciation.up_to(year.stopped_on).where(locked: false)
    end

    def get_loan_repayments_to_lock(year)
      LoanRepayment.where('due_on <= ?', year.stopped_on).where(locked: false)
    end
end