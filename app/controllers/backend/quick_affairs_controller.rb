module Backend
  # This controller handles sales and purchases generation from BankStatements.
  class QuickAffairsController < Backend::BaseController
    def new
      return head :bad_request unless nature = params[:nature_id]
      return head :bad_request unless params[:bank_statement_item_ids]
      @bank_statement_items = BankStatementItem.where(id: params[:bank_statement_item_ids])
      return head :bad_request unless @bank_statement_items

      date     = @bank_statement_items.minimum(:transfered_on)
      @trade   = self.class::Trade.new(invoiced_at: date, nature_id: nature)
      @trade.items.new

      @amount   = @bank_statement_items.sum(:debit) - @bank_statement_items.sum(:credit)
      @amount  *= self.class::Payment.sign_of_amount

      @payment = self.class::Payment.new(to_bank_at: date, amount: @amount)
      @affair  = new_affair(@trade)
      @redirect_to = params[:redirect]
    end

    def create
      return head :bad_request unless payment_params[:bank_statement_item_ids]
      @bank_statement_items = BankStatementItem.where(id: payment_params[:bank_statement_item_ids])
      return head :bad_request unless @bank_statement_items

      @mode_for = {
        trade: params[:"mode-trade"],
        payment: params[:"mode-payment"]
      }

      @trade = new_trade
      @payment = new_payment(@trade.third, @trade.invoiced_at)
      @affair = new_affair(@trade, @trade.third)

      begin
        @affair.transaction do
          unless @affair.valid? && @trade.valid? && @payment.valid?
            @redirect_to = params[:redirect]
            @trade.items.new if @trade.items.size.zero?
            return render :new
          end
          @affair.save!  && @affair.reload
          @trade.save!   && @trade.reload
          @payment.save! && @payment.reload

          @affair.attach @trade
          @affair.attach @payment
        end
      rescue
        notify_error :could_not_attach_x_or_y_to_affair.tl(trade: self.class::Trade.model_name.human, payment: self.class::Payment.model_name.human)
        @redirect_to = params[:redirect]
        return render :new
      end

      @amount  = @bank_statement_items.sum(:debit) - @bank_statement_items.sum(:credit)
      @amount *= self.class::Payment.sign_of_amount

      if lettrable?
        @payment.letter_with @bank_statement_items
      else
        notify_warning :saved_but_couldnt_letter_x_and_y.tl(trade: self.class::Trade.model_name.human, payment: self.class::Payment.model_name.human)
      end
      redirect_to(params[:redirect] || send(:"backend_#{self.class::Trade.affair_class.name.underscore}_path", @affair))
    end

    protected

    def new_trade
      return self.class::Trade.find_by(id: affair_params[:trade_id]) if @mode_for[:trade] =~ /existing/
      third_param = { self.class::Trade.third_attribute => Entity.find_by(id: affair_params[:third_id]) }
      self.class::Trade.new(trade_params.merge(third_param))
    end

    def new_payment(third, at)
      return self.class::Payment.find_by(id: affair_params[:payment_id]) if @mode_for[:payment] =~ /existing/
      payment_attributes = payment_params
        .except(:bank_statement_item_ids)
        .merge(self.class::Payment.third_attribute => third)
        .merge(responsible: current_user, to_bank_at: at)
      self.class::Payment.new payment_attributes
    end

    def new_affair(trade, third = nil)
      self.class::Trade.affair_class.new(currency: trade.default_currency, third: third)
    end

    def use_existing?(name)
      params[:affair][:"use_existing_#{name}"].present?
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

    def lettrable?
      bank_statement   = @bank_statement_items.first.bank_statement
      amount_matches   = (@amount == @payment.amount)
      amount_matches &&= (@amount == @trade.amount)
      mode_is_valid    = (bank_statement.cash_id == @payment.mode.cash_id)
      amount_matches && mode_is_valid
    end
  end
end
