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
      @locked_item = FinancialYearExchange.opened.at(safe_params[:transfered_on]).exists?

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

    def create_vat_payment
      return head :bad_request unless params[:bank_statement_item_ids].present? && params[:nature].present?

      bsi = BankStatementItem.where(id: params[:bank_statement_item_ids])

      return head :bad_request unless bsi

      fy = FinancialYear.on(bsi.first.transfered_on)
      amount  = bsi.sum(:debit) - bsi.sum(:credit)
      tax_payment = TaxPayment.create!(
        cash_id: bsi.first.cash.id,
        paid_at: bsi.first.transfered_on.to_time,
        nature: params[:nature].to_sym,
        financial_year_id: fy.id,
        amount: amount.abs,
        state: :validated
      )
      tax_payment.letter_with(bsi)
      redirect_to params[:redirect]
    end

    def create_payslip_contribution_payment
      return head :bad_request unless params[:bank_statement_item_ids].present? && params[:payee_id].present?

      bsi = BankStatementItem.where(id: params[:bank_statement_item_ids])

      return head :bad_request unless bsi

      amount  = bsi.sum(:debit) - bsi.sum(:credit)
      payslip_contribution_payment = PayslipContributionPayment.create!(
        mode: bsi.first.cash.outgoing_payment_modes.first,
        to_bank_at: bsi.first.transfered_on.to_time,
        paid_at: bsi.first.transfered_on.to_time,
        amount: amount.abs,
        payee_id: params[:payee_id],
        responsible: current_user,
        delivered: true
      )
      payslip_contribution_payment.letter_with(bsi)
      redirect_to params[:redirect]
    end

    def create_payslip_payment
      return head :bad_request unless params[:bank_statement_item_ids].present? && params[:payee_id].present?

      bsi = BankStatementItem.where(id: params[:bank_statement_item_ids])

      return head :bad_request unless bsi

      amount  = bsi.sum(:debit) - bsi.sum(:credit)
      payslip_payment = PayslipPayment.create!(
        mode: bsi.first.cash.outgoing_payment_modes.first,
        to_bank_at: bsi.first.transfered_on.to_time,
        paid_at: bsi.first.transfered_on.to_time,
        amount: amount.abs,
        payee_id: params[:payee_id],
        responsible: current_user,
        delivered: true
      )
      payslip_payment.letter_with(bsi)
      redirect_to params[:redirect]
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
