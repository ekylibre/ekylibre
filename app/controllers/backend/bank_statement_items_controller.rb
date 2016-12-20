module Backend
  class BankStatementItemsController < Backend::BaseController
    def new
      return head :bad_request unless @bank_statement = BankStatement.find(params[:bank_statement_id])
      @bank_statement_item = BankStatementItem.new(permit_params)
      if request.xhr?
        render partial: 'bank_statement_item_row_form', locals: { item: @bank_statement_item, bank_statement: @bank_statement }
      else
        redirect_to_back
      end
    end

    def create
      @initiator_form = params[:bank_statement_item][:initiator_id]
      return head :bad_request unless @initiator_form && @bank_statement = BankStatement.find(params[:bank_statement_id])
      safe_params = permit_params
      @bank_statement_item = @bank_statement.items.new(safe_params)
      return head :bad_request unless @bank_statement_item.save!
      respond_to do |format|
        format.js { render }
      end
    end

    def destroy
      @bank_statement = BankStatement.find(params[:bank_statement_id])
      @bank_statement_item = @bank_statement.items.find(params[:id])
      id = @bank_statement_item.id
      return head :bad_request unless @bank_statement && @bank_statement_item
      return head :failed unless @bank_statement_item.destroy
      respond_to do |format|
        format.js { render json: { id: id } }
      end
    end

    protected

    def permit_params
      params
        .reject { |_key, value| value == '0.0' || value == '' }
        .require(:bank_statement_item)
        .permit(:debit, :credit, :transfered_on, :initiated_on, :transaction_number, :letter, :name)
    end
  end
end
