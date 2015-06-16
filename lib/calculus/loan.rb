module Calculus

  class Loan

    def initialize(amount, count, options = {})
      @amount = amount
      @count = count
      @interests  = options[:interests] || {}
      @insurances = options[:insurances] || {}
      @period = options[:period] || 1
      @precision = options[:precision] || 2
      @shift = options[:shift] || 0
      @shift_method = options[:shift_method] || :immediate_payment
      @started_on = options[:started_on] || Date.today
    end

    def compute_repayments(repayment_method)
      array = send("compute_#{repayment_method}_repayments")
      array.last[:base_amount] += array.last[:remaining_amount]
      array.last[:remaining_amount] = 0.0
      due_on = @started_on + 1.month
      array.each_with_index do |r, index|
        r[:due_on] = due_on
        r[:position] = index + 1
        due_on += 1.month
      end
      return array
    end

    protected

    # Compute shift period  calculations
    def compute_shift(&block)
      amount = @amount.dup
      return amount unless @shift > 0
      @shift.times do
        repayment = {base_amount: 0}
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
          repayment[name] = (amount * rate / @period).round(@precision)
        end

        repayment[:remaining_amount] = amount
        yield repayment
      end
      return amount
    end

    def compute_constant_rate_repayments
      array = []
      amount = compute_shift do |repayment|
        array << repayment
      end
      m = (amount / @count).round(@precision)
      @count.times do |index|
        repayment = {}
        @interests.each do |name, rate|
          repayment[name] = (amount * rate / @period).round(@precision)
        end
        @insurances.each do |name, rate|
          repayment[name] = (amount * rate / @period).round(@precision)
        end
        repayment[:base_amount] = m
        amount -= repayment[:base_amount]
        repayment[:remaining_amount] = amount
        array << repayment
      end
      return array
    end

    def compute_constant_amount_repayments
      array = []
      amount = compute_shift do |repayment|
        array << repayment
      end
      global_rate = (@interests.values.sum  + @insurances.values.sum)/ @period
      repayment_amount = amount * global_rate / (1 - ( (1 + global_rate) ** -@count))
      @count.times do |index|
        repayment = {}
        @interests.each do |name, rate|
          repayment[name] = (amount * rate / @period).round(@precision)
        end
        @insurances.each do |name, rate|
          repayment[name] = (amount * rate / @period).round(@precision)
        end
        repayment[:base_amount] = (repayment_amount - repayment.values.sum).round(@precision)
        amount -= repayment[:base_amount]
        repayment[:remaining_amount] = amount
        array << repayment
      end
      return array
    end

  end

end
