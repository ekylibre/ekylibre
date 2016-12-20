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
    end

    def create
      raise NotImplementedError, "oh-ho"
    end
  end
end
