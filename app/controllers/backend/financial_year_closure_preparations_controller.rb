module Backend
  class FinancialYearClosurePreparationsController < Backend::BaseController
    def create
      return unless financial_year = FinancialYear.find(params[:financial_year_id])

      begin
        financial_year.update!(state: 'closure_in_preparation', closer: current_user)
      rescue ActiveRecord::RecordInvalid => error
        notify_error(:please_contact_support_for_further_information, message: error.message)
      end
      redirect_to params[:redirect]
    end

    def destroy
      return unless financial_year = FinancialYear.find(params[:financial_year_id])

      begin
        financial_year.update!(state: 'opened', closer: nil)
      rescue ActiveRecord::RecordInvalid => error
        notify_error(:please_contact_support_for_further_information, message: error.message)
      end
      redirect_to params[:redirect]
    end
  end
end
