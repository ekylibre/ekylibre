module Backend
  # This controller handles sales and purchases generation from BankStatements.
  class QuickAffairsController < Backend::BaseController
    def new
      return head :bad_request unless nature = params[:nature_id]
      @bank_statement_items = BankStatementItem.where(id: params[:bank_statement_item_ids]) if params[:bank_statement_item_ids]

      date     = Maybe(@bank_statement_items).minimum(:transfered_on).or_nil
      @trade   = self.class::Trade.new(invoiced_at: date, nature_id: nature)
      @trade.items.new

      @amount   = @bank_statement_items ? @bank_statement_items.sum(:credit) - @bank_statement_items.sum(:debit) : 0
      @amount  *= self.class::Payment.sign_of_amount

      @payment = self.class::Payment.new(to_bank_at: date, amount: @amount)
      @affair  = self.class::Trade.affair_class.new
      @redirect_to = params[:redirect]
    end

    def create
      @bank_statement_items = BankStatementItem.where(id: payment_params[:bank_statement_item_ids].split(' ')) if payment_params[:bank_statement_item_ids]

      @mode_for = {
        trade: params[:"mode-trade"],
        payment: params[:"mode-payment"]
      }

      @trade = new_trade
      @payment = new_payment(@trade.third, @trade.invoiced_at)

      @amount  = @bank_statement_items ? @bank_statement_items.sum(:credit) - @bank_statement_items.sum(:debit) : 0
      @amount *= self.class::Payment.sign_of_amount

      begin
        @trade.transaction do
          unless @trade.valid? && @payment.valid?
            @affair = self.class::Trade.affair_class.new
            @redirect_to = params[:redirect]
            @trade.items.new if @trade.items.size.zero?
            return render :new
          end
          @trade.save!   && @trade.reload
          @payment.save! && @payment.reload
          @affair = @trade.affair
          @affair.third = @trade.third
          @affair.save!

          @affair.attach @payment
        end
      rescue
        notify_error :could_not_attach_x_or_y_to_affair.tl(trade: self.class::Trade.model_name.human, payment: self.class::Payment.model_name.human)
        @redirect_to = params[:redirect]
        return render :new
      end

      lettered = @amount == @trade.amount && @payment.letter_with(@bank_statement_items)
      if !lettered && @bank_statement_items
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
                           .merge(responsible: current_user, to_bank_at: at, paid_at: at)
      self.class::Payment.new payment_attributes
    end

    def use_existing?(name)
      params[:affair][:"use_existing_#{name}"].present?
    end

    def trade_params
      params.require(:trade)
            .permit :invoiced_at,
                    :nature_id,
                    :reference_number,
                    :tax_payability,
                    :description,
                    items_attributes: %i[
                      variant_id
                      quantity
                      amount
                      tax_id
                      reduction_percentage
                      unit_pretax_amount
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
