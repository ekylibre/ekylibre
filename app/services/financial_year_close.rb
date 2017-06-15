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

      # Create result entry of the current year
      generate_result_entry! if @result_journal
      @progress.increment!

      # Settle balance sheet accounts
      # Adds carrying forward entry
      generate_carrying_forward_entry!
      @progress.increment!

      # Close all journals
      Journal.find_each.with_index do |journal, index|
        journal.close!(@to_close_on) if journal.closed_on < @to_close_on
        @progress.increment!
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
    journals = Journal.where('closed_on < ?', @to_close_on)
    unclosables = journals.select { |journal| !journal.closable?(@to_close_on) }

    if unclosables.any?
      unclosable_names = unclosables.map(&:name).to_sentence(locale: :eng)
      raise "Some journals cannot be closed on #{@to_close_on}: " + unclosable_names
    end

    fetch_journals!

    @errors.each { |e| raise e }
  end

  def fetch_journals!
    @result_journal  = options[:result_journal]  || Journal.find_by(id: options[:result_journal_id].to_i )
    @closure_journal = options[:closure_journal] || Journal.find_by(id: options[:closure_journal_id].to_i)
    @forward_journal = options[:forward_journal] || Journal.find_by(id: options[:forward_journal_id].to_i)

    ensure_opened_and_is! @result_journal,  :result
    ensure_opened_and_is! @closure_journal, :closure
    ensure_opened_and_is! @forward_journal, :forward
  end

  def ensure_opened_and_is!(journal, nature)
    return nil unless journal

    return true if journal.send(:"#{nature}?") &&
                                journal.closed_on <= @to_close_on &&
                                journal.currency == @currency

    @errors << "Cannot close without an opened #{nature} journal with same currency as financial year."
  end

  # FIXME: Manage non-french accounts
  def generate_result_entry!
    accounts = []
    accounts << Nomen::Account.find(:expenses).send(Account.accounting_system)
    accounts << Nomen::Account.find(:revenues).send(Account.accounting_system)

    items = []
    total = account_balances_for(accounts).count + 1
    progress = Progress.new(:close_result_entry, id: self.id, max: total)

    account_balances_for(accounts).find_each.with_index do |account_balance, index|
      items << {
        account_id: account_balance.account_id,
        name: account_balance.account.name,
        real_debit: account_balance.balance_credit,
        real_credit: account_balance.balance_debit
      }

      progress.set_value(index + 1)
    end

    return unless items.any?

    # Since debit and credit are reversed, if result is positive, balance is a credit
    # and so it's a profit
    result = items.map { |i| i[:real_debit] - i[:real_credit] }.sum
    if result > 0
      profit = Account.find_in_nomenclature(:financial_year_result_profit)
      items << { account_id: profit.id, name: profit.name, real_debit: 0.0, real_credit: result }
    elsif result < 0
      losses = Account.find_in_nomenclature(:financial_year_result_loss)
      items << { account_id: losses.id, name: losses.name, real_debit: result.abs, real_credit: 0.0 }
    end

    result = @result_journal.entries.create!(
      printed_on: @to_close_on,
      currency: @result_journal.currency,
      state: :confirmed,
      items_attributes: items
    )

    progress.clean!

    result
  end

  # FIXME: Manage non-french accounts
  def generate_carrying_forward_entry!
    account_radices = %w[1 2 3 4 5]
    unlettered_items = []

    accounts = Account.where('accounts.number ~ ?', "^(#{account_radices.join('|')})")
                      .joins(:journal_entry_items)
                      .where('journal_entry_items.printed_on BETWEEN ? AND ?', started_on, to_close_on)
                      .where('journal_entry_items.financial_year_id = ?', id)

    letterable_accounts = accounts.joins(:journal_entry_items)
                                  .where('journal_entry_items.letter IS NOT NULL OR reconcilable')

    unletterable_accounts = accounts.joins(:journal_entry_items)
                                    .where('journal_entry_items.letter IS NULL AND NOT reconcilable')

    progress = Progress.new(:close_carry_forward, id: self.id, max: letterable_accounts.count + unletterable_accounts.count)

    unletterable_accounts.find_each.with_index do |a, index|
      entry_items = a.journal_entry_items
                     .where(financial_year_id: id)
                     .between(started_on, to_close_on)
      balance = entry_items.where(letter: nil).sum('debit - credit')
      next if balance.zero?
      unlettered_items << {
        account_id: a.id,
        name: a.name,
        real_debit: (balance > 0 ? balance : 0),
        real_credit: (-balance > 0 ? -balance : 0)
      }
      progress.set_value(index + 1)
    end

    letterable_accounts.find_each.with_index do |a, index|
      generate_lettering_carry_forward!(a)

      progress.set_value(unletterable_accounts.count + index + 1)
    end

    debit_result = unlettered_items.map { |i| i[:real_debit] }.sum
    credit_result = unlettered_items.map { |i| i[:real_credit] }.sum

    debit_items = unlettered_items.select { |i| i[:real_debit].nonzero? }
    credit_items = unlettered_items.select { |i| i[:real_credit].nonzero? }

    generate_closing_and_opening_entry!(debit_items, debit_result, @to_close_on, @forward_journal, @closure_journal)
    generate_closing_and_opening_entry!(credit_items, -credit_result, @to_close_on, @forward_journal, @closure_journal)
    progress.clean!
  end

  def generate_lettering_carry_forward!(account)
    unbalanced_letters = unbalanced_items_for(account)
    progress = Progress.new(:close_lettering, id: id, max: unbalanced_letters.count)

    unbalanced_letters.each_with_index do |info, index|
      entry_id = info.first
      letter = info.last

      lettering_items = JournalEntry.find(entry_id)
                                    .items
                                    .where(letter: letter, account_id: account.id)
                                    .find_each.map do |item|
                                      {
                                        account_id: account.id,
                                        name: item.name,
                                        real_debit: item.real_debit,
                                        real_credit: item.real_credit
                                      }
                                    end

      result = lettering_items.map { |i| i[:real_debit] - i[:real_credit] }.sum

      entries = generate_closing_and_opening_entry!(lettering_items, result, @to_close_on, @forward_journal, @closure_journal, letter: letter)

      progress.set_value(index + 1)

      entries
    end

    progress.clean!
  end

  def generate_closing_and_opening_entry!(items, result, letter: nil)
    return unless items.any?
    return unless result.nonzero?

    account = Account.find(items.first[:account_id])

    if letter
      new_letter = account.new_letter
      lettered_later = account.journal_entry_items.where('printed_on > ?', @to_close_on).where(letter: letter)
      lettered_later.update_all(letter: new_letter)
      lettered_later.each do |item|
        affair = item.entry.resource && item.entry.resource.affair
        next unless affair

        affair.update(letter: new_letter)
      end

      items = items.map { |item| item[:letter] = new_letter; item }
    end

    generate_closing_or_opening_entry!(@forward_journal,
                                       { number: '891', name: 'Bilan de clôture' },
                                       items,
                                       -result)

    items = items.map do |item|
      swap = item[:real_debit]
      item[:real_debit] = item[:real_credit]
      item[:real_credit] = swap
      item[:letter] = letter if letter
      item
    end

    generate_closing_or_opening_entry!(@closure_journal,
                                       { number: '890', name: 'Bilan d’ouverture' },
                                       items,
                                       result)
  end

  def generate_closing_or_opening_entry!(journal, account_info, items, result)
    return unless journal
    account = Account.find_or_create_by_number(account_info[:number], account_info[:name])

    journal.entries.create!(
      printed_on: to_close_on,
      currency: journal.currency,
      items_attributes: items + [{
        account_id: account.id,
        name: account.name,
        (result > 0 ? :real_debit : :real_credit) => result.abs
      }]
    )
  end

  def unbalanced_items_for(account, include_nil: false)
    items = account
            .journal_entry_items
            .between(started_on, @to_close_on)
    items = items.where.not(letter: nil) unless include_nil

    items
      .pluck(:letter, :entry_id, :debit, :credit)
      .group_by(&:first)
      .select { |_letter, lines| lines.map { |i| i[2] - i[3] }.sum.nonzero? }
      .values
      .flatten(1)
      .map { |item| item.first(2).reverse }
      .uniq
  end

  def account_balances_for(account_numbers)
    @year.account_balances.joins(:account)
                          .where('local_balance != ?', 0)
                          .where('accounts.number ~ ?', "^(#{account_numbers.join('|')})")
                          .order('accounts.number')
  end
end
