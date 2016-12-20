module Backend
  # This controller handles sales and purchases generation from BankStatements.
  class QuickAffairsController < Backend::BaseController
    def new
      return head :bad_request unless @mode = find_mode
      return head :bad_request unless nature = params[:nature_id]
      return head :bad_request unless params[:bank_statement_item_ids] && @bank_statement_items = BankStatementItem.where(id: params[:bank_statement_item_ids])
      affair_class, trade_class, payment_class, coeff = *classes_for(@mode)

      @date    = @bank_statement_items.minimum(:transfered_on)
      @trade   = trade_class.new(invoiced_at: @date, nature_id: nature)
      @trade.items.new
      @amount  = amount(@bank_statement_items, coeff)
      @payment = payment_class.new(to_bank_at: @date, amount: @amount)
      @affair  = new_affair(affair_class, @trade)
      t3e trade: trade_class.model_name.human, payment: payment_class.model_name.human
      @redirect_to = params[:redirect]
    end

    def create
      return head :bad_request unless @mode = find_mode
      @bank_statement_items = BankStatementItem.where(id: payment_params[:bank_statement_item_ids])
      return head :bad_request unless payment_params[:bank_statement_item_ids] && @bank_statement_items
      affair_class, trade_class, payment_class, coeff = *classes_for(@mode)

      @trade = new_trade(trade_class)
      @payment = new_payment(payment_class, @trade.third, @trade.invoiced_at)
      @affair = new_affair(affair_class, @trade)

      begin
        @affair.transaction do
          return render :new unless @affair.valid? && @trade.valid? && @payment.valid?
          @affair.save!  && @affair.reload
          @trade.save!   && @trade.reload
          @payment.save! && @payment.reload

          @affair.attach(@trade)
          @affair.attach(@payment)
        end
      rescue
        notify_info "Could not attach trade and payment to Affair"
        return render :new
      end

      @amount = amount(@bank_statement_items, coeff)
      bank_statement = @bank_statement_items.first.bank_statement
      lettrable      = (@amount == @payment.amount)
      lettrable    &&= (@amount == @trade.amount)
      lettrable    &&= (bank_statement.cash_id == @payment.mode.cash_id)
      @payment.letter_with(@bank_statement_items) if lettrable
      redirect_to(params[:redirect] || send(:"backend_#{affair_class.name.underscore}_path", @affair))
    end

    protected

    def classes_for(mode)
      payment_class = "#{@mode}_payment".classify.constantize
      trade_class, coeff = *case @mode
                            when /incoming/ then [Sale,      1]
                            when /outgoing/ then [Purchase, -1]
                            else raise 'Somehow managed to avoid the guard-clause???'
                            end
      affair_class = (trade_class.name + 'Affair').classify.constantize
      [affair_class, trade_class, payment_class, coeff]
    end

    def new_trade(klass)
      existing = params[:affair][:"mode-trade"] =~ /existing/
      return klass.find(affair_params[:trade_id]) if existing && params[:affair][:trade_id]
      klass.new(trade_params.merge(klass.third_attribute => Entity.find(affair_params[:third_id])))
    end

    def new_payment(klass, third, at)
      existing = params[:affair][:"mode-payment"] =~ /existing/
      return klass.find(affair_params[:payment_id]) if existing && params[:affair][:payment_id]
      payment_attributes = payment_params.dup
      payment_attributes.delete(:bank_statement_item_ids)
      klass.new payment_attributes.merge(responsible: current_user, to_bank_at: at, klass.third_attribute => third)
    end

    def new_affair(klass, trade)
      currency = trade.currency || trade.nature.currency
      klass.new(currency: currency, third: trade.third)
    end

    def use_existing?(name)
      params[:affair][:"use_existing_#{name}"].present?
    end

    def amount(bank_statement_items, coeff)
      coeff * (bank_statement_items.sum(:debit) - bank_statement_items.sum(:credit))
    end

    def find_mode
      params[:mode] if params[:mode] =~ /incoming|outgoing/
    end

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
                    :amount,
                    :bank_statement_item_ids
    end

    def affair_params
      params.require(:affair)
            .permit :trade_id,
                    :third_id,
                    :payment_id
    end
  end
end
