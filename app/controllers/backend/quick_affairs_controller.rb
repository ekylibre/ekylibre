module Backend
  # This controller handles sales and purchases generation from BankStatements.
  class QuickAffairsController < Backend::BaseController
    def new
      return head :bad_request unless (mode = params[:mode]) =~ /incoming|outgoing/
      return head :bad_request unless nature = params[:nature_id]
      return head :bad_request unless params[:bank_statement_item_ids] && @bank_statement_items = BankStatementItem.where(id: params[:bank_statement_item_ids])
      payment_class = "#{mode}_payment".classify.constantize
      trade_class, coeff = *case mode
                            when /incoming/ then [Sale,    -1]
                            when /outgoing/ then [Purchase, 1]
                            else raise 'Somehow managed to avoid the guard-clause???'
                            end
      @date    = @bank_statement_items.minimum(:transfered_on)
      @trade   = trade_class.new(invoiced_at: @date, nature_id: nature)
      @trade.items.new
      @payment = payment_class.new(to_bank_at: @date)
      @amount  = @bank_statement_items.sum(:debit) - @bank_statement_items.sum(:credit)
      @amount *= coeff
      t3e trade: trade_class.model_name.human, payment: payment_class.model_name.human
      @redirect_to = params[:redirect]
    end

    def create
      third = trade_params.slice(:supplier_id, :client_id).compact.keys.first
      return head :bad_request unless third
      trade_class, payment_class = *case third
                                    when /supplier_id/ then [Purchase, OutgoingPayment]
                                    when /client_id/   then [Sale,     IncomingPayment]
                                    else raise 'Somehow managed to avoid the guard-clause???'
                                    end
      affair_class = (trade_class.name + 'Affair').classify.constantize

      @trade   = trade_class.new(trade_params)
      currency = @trade.currency || @trade.nature.currency
      @payment = payment_class.new(payment_params.merge(responsible: current_user, to_bank_at: @trade.invoiced_at, payment_class.third_attribute => @trade.third ))
      @affair  = affair_class.new(currency: currency, third: @trade.third)
      @trade.affair = @affair
      @payment.affair = @affair
      return render :new unless @affair.valid? && @trade.valid? && @payment.valid?
      @affair.save!
      @trade.save!
      @payment.save!
      redirect_to(params[:redirect] || send(:"backend_#{affair_class.name.underscore}_path", @affair))
    end

    protected

    def trade_params
      params.require(:trade)
            .permit :supplier_id,
                    :client_id,
                    :invoiced_at,
                    :nature_id,
                    items_attributes: [
                      :variant_id,
                      :quantity,
                      :amount,
                      :tax_id,
                      :reduction_percentage,
                      :unit_pretax_amount
                    ]
    end

    def payment_params
      params.require(:payment)
            .permit :mode_id,
                    :amount
    end
  end
end
