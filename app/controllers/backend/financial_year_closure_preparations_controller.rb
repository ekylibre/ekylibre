module Backend
  class FinancialYearClosurePreparationsController < Backend::BaseController
    def create
      return unless financial_year = FinancialYear.find(params[:financial_year_id])
      financial_year.update(state: 'closure_in_preparation', closer: current_user)
      redirect_to params[:redirect]
    end

    def destroy
      return unless financial_year = FinancialYear.find(params[:financial_year_id])
      financial_year.update(state: 'opened', closer: nil)
      redirect_to params[:redirect]
    end
  end
end
