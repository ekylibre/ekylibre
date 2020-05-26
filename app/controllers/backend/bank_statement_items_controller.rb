module Backend
  class BankStatementItemsController < Backend::BaseController
    def new
      return head :bad_request unless @bank_statement = BankStatement.find(params[:bank_statement_id])
      @bank_statement_item = BankStatementItem.new(permitted_params)
      if request.xhr?
        render partial: 'bank_statement_item_row_form', locals: { item: @bank_statement_item, bank_statement: @bank_statement }
      else
        redirect_to_back
      end
    end

    def show
      @bank_statement_item = BankStatementItem.find(params[:id])
      return head :bad_request unless @bank_statement_item
      t3e @bank_statement_item
      # redirect_to action: :show, controller: 'backend/bank_statements', id: @bank_statement_item.bank_statement_id
    end

    def create
      @initiator_form = params[:bank_statement_item][:initiator_id]
      return head :bad_request unless @initiator_form && @bank_statement = BankStatement.find(params[:bank_statement_item][:bank_statement_id])
      safe_params = permitted_params
      @bank_statement_item = @bank_statement.items.new(safe_params)

      respond_to do |format|
        if @bank_statement_item.save
          format.js { render }
        else
          format.js { render 'error' }
        end
      end
    end

    def destroy
      @bank_statement_item = BankStatementItem.find(params[:id])

      id = @bank_statement_item.id
      return head :bad_request unless @bank_statement_item
      return head :failed unless @bank_statement_item.destroy
      respond_to do |format|
        format.js { render json: { id: id } }
      end
    end

    protected

    def permitted_params
      params
        .reject { |_key, value| value == '0.0' || value == '' }
        .require(:bank_statement_item)
        .permit(:debit, :credit, :transfered_on, :initiated_on, :transaction_number, :letter, :name)
    end
  end
end
