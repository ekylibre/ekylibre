# coding: utf-8

class FinancialYearClose
  def initialize(year, to_close_on, options = {})
    @year = year
    @started_on = @year.started_on
    @to_close_on = to_close_on || options[:to_close_on] || @year.stopped_on
    @progress = Progress.new(:close_main, id: @year.id, max: 4)
    @errors = []
    @currency = @year.currency
    @options = options
  end

  def execute
    return false unless @year.closable?
    ensure_closability!

    ActiveRecord::Base.transaction do
      @year.compute_balances!
      @progress.increment!

      generate_result_entry! if @result_journal
      @progress.increment!

      disable_partial_lettering

      generate_carrying_forward_entry!
      @progress.increment!

      enable_partial_lettering

      Journal.find_each do |journal|
        journal.close!(@to_close_on) if journal.closed_on < @to_close_on
      end
      @progress.increment!

      @year.update_attributes(stopped_on: @to_close_on, closed: true, state: 'closed')
    end

    true
  ensure
    @progress.clean!
  end

  private

  def ensure_closability!
    journals = Journal.where('closed_on < ?', @to_close_on)
    unclosables = journals.reject { |journal| journal.closable?(@to_close_on) }

    if unclosables.any?
      unclosable_names = unclosables.map(&:name).to_sentence(locale: :eng)
      raise "Some journals cannot be closed on #{@to_close_on}: " + unclosable_names
    end

    fetch_journals!

    @errors.each { |e| raise e }
  end

  def fetch_journals!
    @result_journal  = @options[:result_journal]  || Journal.find_by(id: @options[:result_journal_id].to_i)
    @closure_journal = @options[:closure_journal] || Journal.find_by(id: @options[:closure_journal_id].to_i)
    @forward_journal = @options[:forward_journal] || Journal.find_by(id: @options[:forward_journal_id].to_i)

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
    accounts = %i[expenses revenues]
    accounts = accounts.map { |acc| Nomen::Account.find(acc).send(Account.accounting_system) }

    total = account_balances_for(accounts).count + 1
    progress = Progress.new(:close_result_entry, id: @year.id, max: total)

    items = account_balances_for(accounts).find_each.map do |account_balance|
      progress.increment!

      {
        account_id: account_balance.account_id,
        name: account_balance.account.name,
        real_debit: account_balance.balance_credit,
        real_credit: account_balance.balance_debit,
        state: :confirmed
      }
    end

    return unless items.any?

    # Since debit and credit are reversed, if result is positive, balance is a credit
    # and so it's a profit
    result = items.map { |i| i[:real_debit] - i[:real_credit] }.sum

    items << loss_or_profit_item(result) unless result.zero?

    @result_journal.entries.create!(
      printed_on: @to_close_on,
      currency: @result_journal.currency,
      items_attributes: items,
      state: :confirmed
    )
  ensure
    progress.clean!
  end

  def loss_or_profit_item(result)
    if result > 0
      profit = Account.find_by(usage: :financial_year_result_profit)
      return { account_id: profit.id, name: profit.name, real_debit: 0.0, real_credit: result, state: :confirmed }
    end
    losses = Account.find_by(usage: :financial_year_result_loss)
    { account_id: losses.id, name: losses.name, real_debit: result.abs, real_credit: 0.0, state: :confirmed }
  end

  # FIXME: Manage non-french accounts
  def generate_carrying_forward_entry!
    account_radices = %w[1 2 3 4 5]
    unlettered_items = []

    accounts = Account.where('accounts.number ~ ?', "^(#{account_radices.join('|')})")
                      .joins(:journal_entry_items)
                      .where('journal_entry_items.printed_on BETWEEN ? AND ?', @started_on, @to_close_on)
                      .where('journal_entry_items.financial_year_id = ?', @year.id)

    letterable_accounts = accounts.joins(:journal_entry_items)
                                  .where('journal_entry_items.letter IS NOT NULL OR reconcilable')
                                  .uniq

    unletterable_accounts = accounts.joins(:journal_entry_items)
                                    .where('journal_entry_items.letter IS NULL AND NOT reconcilable')
                                    .uniq

    progress = Progress.new(:close_carry_forward, id: @year.id, max: letterable_accounts.count + unletterable_accounts.count)

    unletterable_accounts.find_each do |a|
      entry_items = a.journal_entry_items
                     .where(financial_year_id: @year.id)
                     .between(@started_on, @to_close_on)
      balance = entry_items.where(letter: nil).sum('debit - credit')
      next if balance.zero?
      unlettered_items << {
        account_id: a.id,
        name: a.name,
        real_debit: (balance > 0 ? balance : 0),
        real_credit: (-balance > 0 ? -balance : 0),
        state: :confirmed
      }
      progress.increment!
    end

    letterable_accounts.find_each do |a|
      generate_lettering_carry_forward!(a)

      progress.increment!
    end

    debit_result = unlettered_items.map { |i| i[:real_debit] }.sum
    credit_result = unlettered_items.map { |i| i[:real_credit] }.sum

    debit_items = unlettered_items.select { |i| i[:real_debit].nonzero? }
    credit_items = unlettered_items.select { |i| i[:real_credit].nonzero? }

    generate_closing_and_opening_entry!(debit_items, debit_result)
    generate_closing_and_opening_entry!(credit_items, -credit_result)
  ensure
    progress.clean!
  end

  def generate_lettering_carry_forward!(account)
    unbalanced_letters = unbalanced_items_for(account, include_nil: true)
    progress = Progress.new(:close_lettering, id: @year.id, max: unbalanced_letters.count)

    reletterings = {}

    unbalanced_letters.each do |entry_id, letter|
      letter_match = letter ? [letter, letter + '*'] : nil

      lettering_items = JournalEntryItem.where(entry_id: entry_id, letter: letter_match, account: account)
                                        .find_each.map do |item|
        {
          account_id: account.id,
          name: item.name,
          real_debit: item.real_debit,
          real_credit: item.real_credit,
          state: :confirmed
        }
      end

      result = lettering_items.map { |i| i[:real_debit] - i[:real_credit] }.sum

      new_letter = generate_closing_and_opening_entry!(lettering_items, result, letter: letter)
      reletterings[letter] = new_letter unless letter.nil? && new_letter.nil?
      progress.increment!
    end
    # Update letters globally
    reletterings.each do |letter, new_letter|
      update_lettered_later!(letter, new_letter, account.id)
    end
  ensure
    progress.clean!
  end

  def generate_closing_and_opening_entry!(items, result, letter: nil)
    return unless items.any?
    return unless result.nonzero?

    new_letter, items = reletter_items!(items, letter)

    generate_closing_or_opening_entry!(@forward_journal,
                                       { number: '890', name: 'Bilan d’ouverture' },
                                       items,
                                       -result,
                                       printed_on: @to_close_on + 1.day)

    items = items.map do |item|
      item[:real_debit], item[:real_credit] = item[:real_credit], item[:real_debit]
      item[:letter] = nil
      item
    end

    generate_closing_or_opening_entry!(@closure_journal,
                                       { number: '891', name: 'Bilan de clôture' },
                                       items,
                                       result)
    new_letter
  end

  def reletter_items!(items, letter)
    return [nil, items] unless letter

    account_id = items.first[:account_id]

    @letter_matcher ||= {}
    @letter_matcher[account_id] ||= {}
    @letter_matcher[account_id][letter] ||= Account.find(account_id).new_letter
    new_letter = @letter_matcher[account_id][letter]

    items = items.map { |item| item[:letter] = new_letter; item }

    [new_letter, items]
  end

  def update_lettered_later!(letter, new_letter, account_id)
    return if letter == new_letter
    lettered_later = JournalEntryItem.includes(:entry).where(account_id: account_id, letter: letter).where('journal_entry_items.printed_on > ?', @to_close_on)
    lettered_later.update_all(letter: new_letter)

    Affair.affairable_types.each do |type|
      model = type.constantize
      table = model.table_name
      root_model = model.table_name.singularize.camelize
      query = "UPDATE affairs SET letter = #{ActiveRecord::Base.connection.quote(new_letter)} " \
              '  FROM journal_entry_items AS jei' \
              "    JOIN #{table} AS res ON (resource_id = res.id AND resource_type = #{ActiveRecord::Base.connection.quote(root_model)}) " \
              "  WHERE jei.account_id = #{account_id} AND jei.letter = #{ActiveRecord::Base.connection.quote(letter)} AND jei.printed_on > #{ActiveRecord::Base.connection.quote(@to_close_on)} "
      '    AND res.affair_id = affairs.id'
      Affair.connection.execute query
    end
  end

  def disable_partial_lettering
    ActiveRecord::Base.connection.execute('ALTER TABLE journal_entry_items DISABLE TRIGGER compute_partial_lettering_status_insert_delete')
    ActiveRecord::Base.connection.execute('ALTER TABLE journal_entry_items DISABLE TRIGGER compute_partial_lettering_status_update')
  end

  def enable_partial_lettering
    account_letterings = <<-SQL.strip_heredoc
        SELECT account_id,
          RTRIM(letter, '*') AS letter_radix,
          SUM(debit) = SUM(credit) AS balanced,
          RTRIM(letter, '*') || CASE WHEN SUM(debit) <> SUM(credit) THEN '*' ELSE '' END
            AS new_letter
        FROM journal_entry_items AS jei
        WHERE account_id IS NOT NULL AND LENGTH(TRIM(COALESCE(letter, ''))) > 0
        GROUP BY account_id, RTRIM(letter, '*')
    SQL

    ActiveRecord::Base.connection.execute <<-SQL.strip_heredoc
        UPDATE journal_entry_items AS jei
          SET letter = ref.new_letter
          FROM (#{account_letterings}) AS ref
          WHERE jei.account_id = ref.account_id
            AND RTRIM(COALESCE(jei.letter, ''), '*') = ref.letter_radix
            AND letter <> ref.new_letter;
    SQL
    ActiveRecord::Base.connection.execute('ALTER TABLE journal_entry_items ENABLE TRIGGER compute_partial_lettering_status_insert_delete')
    ActiveRecord::Base.connection.execute('ALTER TABLE journal_entry_items ENABLE TRIGGER compute_partial_lettering_status_update')
  end

  def generate_closing_or_opening_entry!(journal, account_info, items, result, printed_on: @to_close_on)
    return unless journal
    account = Account.find_by(number: account_info[:number].ljust(8, '0'))
    account ||= Account.create!(number: account_info[:number].ljust(8, '0'), name: account_info[:name])

    journal.entries.create!(
      state: :confirmed,
      printed_on: printed_on,
      currency: journal.currency,
      items_attributes: items + [{
        account_id: account.id,
        name: account.name,
        (result > 0 ? :real_debit : :real_credit) => result.abs,
        state: :confirmed
      }]
    )
  end

  def unbalanced_items_for(account, include_nil: false)
    items = account
            .journal_entry_items
            .between(@started_on, @to_close_on)
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
