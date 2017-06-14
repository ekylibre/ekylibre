class FinancialYearClose
  def initialize(year, to_close_on, options = {})
    @year = year
    @to_close_on = to_close_on || options[:to_close_on] || @year.stopped_on
    @progress = Progress.new(:close_main, id: self.id, max: 2 + Journal.count)
    @errors = []
    @currency = @year.currency
  end

  def execute
    return false unless @year.closable?

    ensure_closability!

    ActiveRecord::Base.transaction do
      # Compute balance of closed year
      @year.compute_balances!

      if @result_journal
        # Create result entry of the current year
        @year.generate_result_entry!(@result_journal, @to_close_on)
      end
      @progress.set_value(1)

      # Settle balance sheet accounts
      # Adds carrying forward entry
      @year.generate_carrying_forward_entry!(@forward_journal, @closure_journal, @to_close_on)
      @progress.set_value(2)

      # Close all journals
      Journal.find_each.with_index do |journal, index|
        journal.close!(@to_close_on) if journal.closed_on < @to_close_on
        @progress.set_value(3 + index)
      end

      # Close year
      @year.update_attributes(stopped_on: @to_close_on, closed: true)
    end
    @progress.clean!
    true
  end

  private

  def ensure_closability!
    # Check closeability of journals
    unclosables = Journal.where('closed_on < ?', @to_close_on).reject do |journal|
      journal.closable?(@to_close_on)
    end
    if unclosables.any?
      raise "Some journals cannot be closed on #{@to_close_on}: " + unclosables.map(&:name).to_sentence(locale: :eng)
    end

    fetch_journals!

    @errors.each { |e| raise e }
  end

  def fetch_journals!
    @result_journal  = options[:result_journal]  || Journal.find_by(id: options[:result_journal_id].to_i )
    @closure_journal = options[:closure_journal] || Journal.find_by(id: options[:closure_journal_id].to_i)
    @forward_journal = options[:forward_journal] || Journal.find_by(id: options[:forward_journal_id].to_i)

    ensure_opened! @result_journal,  :result
    ensure_opened! @closure_journal, :closure
    ensure_opened! @forward_journal, :forward
  end

  def ensure_opened!(journal, nature)
    return nil unless journal

    return true if journal.send(:"#{nature}?") &&
                                journal.closed_on <= @to_close_on &&
                                journal.currency == @currency

    @errors << "Cannot close without an opened #{nature} journal with same currency as financial year."
  end
end
