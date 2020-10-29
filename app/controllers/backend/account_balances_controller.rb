module Backend
  class AccountBalancesController < Backend::BaseController
    layout false

    def show
      account = Account.find(params[:id])
      date = params[:date].present? ? Date.parse(params[:date]) : nil
      @totals = account.totals(date, true)
    end
  end
end
