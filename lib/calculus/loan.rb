module Calculus
  class Loan
    def initialize(amount, count, options = {})
      @amount = amount
      @count = count
      @interests  = options[:interests] || {}
      @insurances = options[:insurances] || {}
      @period = options[:period] || 1
      @length = options[:length] || 1.year
      @precision = options[:precision] || 2
      @shift = options[:shift] || 0
      @shift_method = options[:shift_method] || :immediate_payment
      @insurance_method = :"compute_#{options[:insurance_method]}_insurance" || :compute_to_repay_insurance
      @started_on = options[:started_on] || Time.zone.today
    end

    def compute_repayments(repayment_method)
      array = send("compute_#{repayment_method}_repayments")
      array.last[:base_amount] += array.last[:remaining_amount]
      array.last[:remaining_amount] = 0.0
      due_on = @started_on # why ? + 1.month
      array.each_with_index do |r, index|
        r[:due_on] = due_on
        r[:position] = index + 1
        due_on += @length
      end
      array
    end

    protected

    # Compute shift period  calculations
    def compute_shift(&_block)
      amount = @amount.dup
      return amount unless @shift > 0
      @shift.times do
        repayment = { base_amount: 0 }
        # Interests
        if @shift_method == :anatocism
          @interests.each do |name, rate|
            repayment[name] = 0
            amount += (@amount * rate / @period).round(@precision)
          end
        else
          @interests.each do |name, rate|
            repayment[name] = (@amount * rate / @period).round(@precision)
          end
        end

        # Insurances
        @insurances.each do |name, rate|
          repayment[name] = send(@insurance_method, rate, amount)
        end

        repayment[:remaining_amount] = amount
        yield repayment
      end
      amount
    end

    def compute_constant_rate_repayments
      array = []
      amount = compute_shift do |repayment|
        array << repayment
      end
      m = (amount / @count).round(@precision)
      @count.times do |_index|
        repayment = {}
        @interests.each do |name, rate|
          repayment[name] = (amount * rate / @period).round(@precision)
        end
        @insurances.each do |name, rate|
          repayment[name] = send(@insurance_method, rate, amount)
        end
        repayment[:base_amount] = m
        amount -= repayment[:base_amount]
        repayment[:remaining_amount] = amount
        array << repayment
      end
      array
    end

    def compute_constant_amount_repayments
      array = []
      amount = compute_shift do |repayment|
        array << repayment
      end
      in_rate = []
      in_rate << @interests
      in_rate << @insurances if @insurance_method == :compute_to_repay_insurance

      global_rate = in_rate.map(&:values).flatten.sum / @period
      repayment_amount = amount * global_rate / (1 - ((1 + global_rate)**-@count))

      @count.times do |_index|
        repayment = {}
        @interests.each do |name, rate|
          repayment[name] = (amount * rate / @period).round(@precision)
        end
        @insurances.each do |name, rate|
          repayment[name] = send(@insurance_method, rate, amount)
        end

        costs = repayment.slice(*in_rate.map(&:keys).flatten).values.sum

        repayment[:base_amount] = (repayment_amount - costs).round(@precision)
        amount -= repayment[:base_amount]
        repayment[:remaining_amount] = amount
        array << repayment
      end
      array
    end

    def compute_initial_insurance(rate, _amount)
      compute_insurance(rate, @amount)
    end

    def compute_insurance(rate, amount)
      (amount * rate / @period).round(@precision)
    end
    alias compute_to_repay_insurance compute_insurance
  end
end
