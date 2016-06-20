module Backend
  class BankStatementItemsController < Backend::BaseController
    def new
      @bank_statement_item = BankStatementItem.new
      permitted_params = params.permit(:debit, :credit, :transfered_on, :letter, :name, :bank_statement_id)
      @bank_statement_item.attributes = permitted_params
      if request.xhr?
        render partial: 'reconciliation_row_form', object: @bank_statement_item
      else
        redirect_to_back
      end
    end
  end
end
