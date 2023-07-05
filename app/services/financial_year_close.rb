# frozen_string_literal: true

class FinancialYearClose
  class << self
    # @param [FinancialYear] year
    # @param [User] user
    # @param [Date] close_on
    # @return [FinancialYearClose]
    def for_year(year, user:, close_on:, **options)
      new(year, close_on, user, **options)
    end
  end

  attr_reader :carry_forward_account, :close_error

  class UnbalancedBalanceSheet < StandardError; end

  CLOSURE_STEPS = {
    0 => 'generate_documents_prior_to_closure',
    1 => 'compute_balances',
    2 => 'close_result_entry',
    3 => 'close_carry_forward',
    4 => 'allocate_result',
    5 => 'journals_closure',
    6 => 'generate_documents_post_closure'
  }.freeze

  def initialize(year, to_close_on, closer, disable_document_generation: false, **options)
    @year = year
    @started_on = @year.started_on
    @closer = closer
    @to_close_on = to_close_on || options[:to_close_on] || @year.stopped_on
    @progress = Progress.new(:close_main, id: @year.id, max: CLOSURE_STEPS.count)
    @errors = []
    @logger ||= Logger.new(File.join(Rails.root, 'log', "closure-#{Ekylibre::Tenant.current.to_s}-#{@to_close_on.to_s}.log"))
    @currency = @year.currency
    @disable_document_generation = disable_document_generation
    @options = options
  end

  def say(message)
    now = Time.now
    moment = '[' + sprintf('%.1f', now - @start).rjust(6).red + ' '
    # puts @counts.stringify_keys.to_yaml.cyan if @counts

    if @previous_now
      moment << sprintf('%.2f', now - @previous_now).rjust(6).green
    else
      moment << '—' * 6
    end
    moment << '] '

    t = moment + message.yellow
    # puts t
    Rails.logger.info(t)
    now
  end

  def log(message)
    @previous_now = say(message) unless Rails.env.test?
  end

  def cinc(name, increment = 1)
    @counts ||= {}
    @counts[name] ||= 0
    @counts[name] += 1
  end

  def benchmark(message)
    start = Time.now
    moment = '[' + format('%.1f', start - @start).rjust(6).red + '] '
    Rails.logger.info(moment + message.yellow + '...')
    # puts moment + message.yellow + '...'
    yield
    stop = Time.now
    # puts moment + message.yellow + " (done in #{sprintf('%.2f', stop - start).green}s)"
    Rails.logger.info(moment + message.yellow + " (done in #{format('%.2f', stop - start).green}s)")
  end

  def execute
    @start = Time.now
    @logger.info("------- Closure for year ID : #{@year.id.to_s} -----------")
    return false unless @year.closable?

    @logger.info('0 - Verify closability')
    ensure_closability!

    ApplicationRecord.transaction do

      @logger.info((CLOSURE_STEPS[0]).to_s)
      @year.update_attributes({ state: 'opened' })
      @logger.info('1 - Dump tenant')
      dump_tenant
      @logger.info('2 - Generate documents')
      generate_documents('prior_to_closure')
      @progress.increment!

      @logger.info((CLOSURE_STEPS[1]).to_s)
      benchmark('Compute Balance') do
        @logger.info('3 - Compute Balance')
        @year.compute_balances!
        @progress.increment!
      end

      @logger.info((CLOSURE_STEPS[2]).to_s)
      benchmark('Generate Result Entry') do
        @logger.info('4 - Generate result entry')
        generate_result_entry!
        @progress.increment!
      end

      @logger.info((CLOSURE_STEPS[3]).to_s)
      log("Disable Partial Lettering Triggers")
      @logger.info("5 - Disable Partial Lettering Triggers")
      disable_partial_lettering
      @logger.info("6 - Generate carrying forward entry")
      generate_carrying_forward_entry!
      log("Enable Partial Lettering Triggers")
      @logger.info("6 bis - Enable Partial Lettering Triggers")
      enable_partial_lettering
      @progress.increment!

      @logger.info((CLOSURE_STEPS[4]).to_s)
      @logger.info("7 - Allocate Result")
      @logger.info("forward_journal_id : #{@forward_journal.id}") if @forward_journal
      allocate_results if @forward_journal
      @logger.info("7 bis - Enable Partial Lettering Triggers")
      enable_partial_lettering
      @progress.increment!

      @logger.info((CLOSURE_STEPS[5]).to_s)
      @logger.info("Locked depreciations repayments")
      locked_depreciations_repayments
      @logger.info("Close Journals")
      Journal.find_each do |journal|
        journal.close!(@to_close_on) if journal.closed_on < @to_close_on
      end
      @progress.increment!

      @logger.info("Close Financial Year")
      @logger.info(@year.balanced_balance_sheet?(:post_closure).to_s)
      raise UnbalancedBalanceSheet.new(:closure_failed_because_balance_sheet_unbalanced.tl) unless @year.balanced_balance_sheet?(:post_closure)

      @logger.info((CLOSURE_STEPS[6]).to_s)
      generate_documents('post_closure')
      @progress.increment!

      @year.update_attributes(stopped_on: @to_close_on, closed: true, state: 'closed')
    end
    @closer.notify(:financial_year_x_successfully_closed, { name: @year.name }, level: :success)
    true
  rescue StandardError => error
    @year.update_columns(state: 'opened')
    FileUtils.rm_rf Ekylibre::Tenant.private_directory.join('attachments', 'documents', 'financial_year_closures', @year.id.to_s)

    Rails.logger.error $!
    Rails.logger.error $!.backtrace.join("\n")
    ExceptionNotifier.notify_exception($!, data: { message: error })

    if error.class == FinancialYearClose::UnbalancedBalanceSheet
      @closer.notify(error.message, {}, level: :error)
    else
      @closer.notify(:financial_year_x_could_not_be_closed, { name: @year.name }, level: :error)
    end
    @close_error = error
    return false
  ensure
    @progress.clean!
  end

  private

    def locked_depreciations_repayments
      # find and locked fixed asset depreciations in current financial year
      FixedAssetDepreciation.up_to(@to_close_on).where(locked: false).update_all(locked: true)
      # find and locked fixed asset depreciations in current financial year
      LoanRepayment.where('due_on <= ?', @to_close_on).where(locked: false).update_all(locked: true)
    end

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
      @result_journal = @options[:result_journal] || Journal.find_by(id: @options[:result_journal_id].to_i)
      @closure_journal = @options[:closure_journal] || Journal.find_by(id: @options[:closure_journal_id].to_i)
      @forward_journal = @options[:forward_journal] || Journal.find_by(id: @options[:forward_journal_id].to_i)

      ensure_opened_and_is! @result_journal, :result
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
      accounts = accounts.map { |acc| Onoma::Account.find(acc).send(Account.accounting_system) }

      balances = @year.account_balances_for(accounts)

      total = balances.count + 1
      progress = Progress.new(:close_result_entry, id: @year.id, max: total)

      items = balances.find_each.map do |account_balance|
        progress.increment!

        {
          account_id: account_balance.account_id,
          name: account_balance.account.name,
          real_debit: account_balance.balance_credit,
          real_credit: account_balance.balance_debit,
          state: :confirmed
        }
      end

      @result = AccountancyComputation.new(@year).sum_entry_items_by_line(:profit_and_loss_statement, :exercice_result)
      @result_account = get_result_account_for(@result)

      if items.any? && @result.to_f != 0.0 && @result_journal.present?

        items << loss_or_profit_item(@result_account, @result)

        return unless @result_journal

        @result_journal.entries.create!(
          printed_on: @to_close_on,
          currency: @result_journal.currency,
          items_attributes: items,
          state: :confirmed
        )
        @logger.info("Result #{@result.to_f} entry created on account id #{@result_account.id}")
      else
        @logger.error("No Result entry : #{@result.to_f}")
      end
    ensure
      progress.clean!
    end

    def get_result_account_for(result)
      if result.positive?
        Account.find_by_usage(:financial_year_result_profit)
      else
        Account.find_by_usage(:financial_year_result_loss)
      end
    end

    def previous_carry_forward_account
      usages = %i[debit_retained_earnings credit_retained_earnings]
      accounts = usages.map { |usage| Account.find_by_usage(usage) }.compact
      return if accounts.compact.blank?

      accounts.find { |account| account.totals[:balance].to_f.nonzero? }
    end

    def loss_or_profit_item(account, result)
      item_attributes = { account_id: account.id, name: account.name, state: :confirmed }
      amount = if result.positive?
                 { real_credit: result }
               else
                 { real_debit: result.abs }
               end
      item_attributes.merge(amount)
    end

    # FIXME: Manage non-french accounts
    def generate_carrying_forward_entry!
      log('Init Carrying Forward Entry Generation')
      account_radices = %w[1 2 3 4 5]
      unlettered_items = []

      accounts = Account.where('accounts.number ~ ?', "^(#{account_radices.join('|')})")
                        .joins(:journal_entry_items)
                        .where('journal_entry_items.printed_on BETWEEN ? AND ?', @started_on, @to_close_on)
                        .where('journal_entry_items.financial_year_id = ?', @year.id)

      letterable_accounts = accounts.joins(:journal_entry_items)
                                    .where('journal_entry_items.letter IS NOT NULL OR reconcilable')
                                    .distinct

      unletterable_accounts = accounts.joins(:journal_entry_items)
                                      .where('journal_entry_items.letter IS NULL AND NOT reconcilable')
                                      .distinct

      progress = Progress.new(:close_carry_forward, id: @year.id,
                              max: letterable_accounts.count + unletterable_accounts.count)

      log "Generate List of Unlettered Items"

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

      log "Generate Lettering Carry Forward for each Letterable Account"
      letterable_accounts.find_each.each_with_index do |a, index|
        log "Generate Lettering Carry Forward for each Account: #{a.number}"
        generate_lettering_carry_forward!(a)
        progress.increment!
      end

      debit_result = unlettered_items.map { |i| i[:real_debit] }.sum
      credit_result = unlettered_items.map { |i| i[:real_credit] }.sum

      debit_items = unlettered_items.select { |i| i[:real_debit].nonzero? }
      credit_items = unlettered_items.select { |i| i[:real_credit].nonzero? }

      log "Generate Closing+Opening Entry Debit Items"
      generate_closing_and_opening_entry!(debit_items, debit_result)
      log "Generate Closing+Opening Entry Credit Items"
      generate_closing_and_opening_entry!(credit_items, -credit_result)
    ensure
      progress.clean!
    end

    def generate_lettering_carry_forward!(account)
      unbalanced_letters = unbalanced_items_for(account, include_nil: true)
      progress = Progress.new(:close_lettering, id: @year.id, max: unbalanced_letters.count)

      reletterings = {}
      items = {}

      unbalanced_letters.each do |entry_id, letter|
        letter &&= letter.gsub('*', '')
        letter_match = letter ? [letter, letter + '*'] : nil

        item_criteria = { entry_id: entry_id, letter: letter_match, account: account }
        items[item_criteria] ||= JournalEntryItem.where(**item_criteria)
        lettering_items = items[item_criteria].find_each.map do |item|
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

      # return unless result.nonzero?

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

    def allocate_results
      result_balance_debit = @result_account.totals[:balance_debit]
      result_balance_credit = @result_account.totals[:balance_credit]
      previous_carry_forward_balance_debit = 0
      previous_carry_forward_balance_credit = 0
      @logger.info("result_balance_debit : #{result_balance_debit}")
      @logger.info("result_balance_credit : #{result_balance_credit}")

      if result_balance_debit.to_f == 0.0 && result_balance_credit.to_f == 0.0
        @logger.error("No value on credit or debit for result for account id : #{@result_account.id}. Maybe result aleready been allocated manually.")
      else
        items = [{
                   name: :balance_of_the_income_statement.tl,
                   real_debit: result_balance_credit,
                   real_credit: result_balance_debit,
                   account_id: @result_account.id
                 }]
        @logger.info("initial items : #{items.inspect}")
        pcfa = previous_carry_forward_account
        previous_carry_forward_balance_debit = 0.0
        previous_carry_forward_balance_credit = 0.0
        if pcfa
          @logger.info("pcfa : #{pcfa.inspect}")
          previous_carry_forward_balance_debit = pcfa.totals[:balance_debit]
          previous_carry_forward_balance_credit = pcfa.totals[:balance_credit]
          @logger.info("previous_carry_forward_balance_debit : #{previous_carry_forward_balance_debit}")
          @logger.info("previous_carry_forward_balance_credit : #{previous_carry_forward_balance_credit}")

          items << {
            name: :balance_allocated_to_retained_earnings.tl,
            real_debit: previous_carry_forward_balance_credit,
            real_credit: previous_carry_forward_balance_debit,
            account_id: pcfa.id
          }

        end

        to_allocate_balance = result_balance_debit - result_balance_credit + previous_carry_forward_balance_debit - previous_carry_forward_balance_credit
        debit_or_credit = to_allocate_balance.positive? ? :debit : :credit

        @logger.info("to_allocate_balance (initial + pcfa) : #{to_allocate_balance} on #{debit_or_credit}")

        @logger.info("allocations : #{@options[:allocations].inspect}")

        @options[:allocations].each do |(number, value)|
          account = Account.find_or_create_by_number(number)
          @logger.info("allocation #{number.to_s} - #{account.name} = #{value.to_s}")
          items << {
            name: :allocation_balance.tl(name: account.name),
            "real_#{debit_or_credit}": value,
            account_id: account.id
          }
        end

        @logger.info("items for allocate result : #{items.inspect}")
        JournalEntry.create!(
          journal: @forward_journal,
          printed_on: @to_close_on + 1.day,
          real_currency: @forward_journal.currency,
          items_attributes: items
        )
      end
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
      # account = Account.find(account_id)
      cinc :update_lettered_later
      if letter == new_letter
        say "Skip Changing Letter #{letter.inspect}"
        return
      end
      benchmark "Changing Letter #{letter} -> #{new_letter}" do
        lettered_later = JournalEntryItem.includes(:entry).where(account_id: account_id, letter: letter).where('journal_entry_items.printed_on > ?', @to_close_on)
        lettered_later.update_all(letter: new_letter)

        Affair.affairable_types.each do |type|
          model = type.constantize
          table = model.table_name
          root_model = model.table_name.singularize.camelize
          query = "UPDATE affairs SET letter = #{ApplicationRecord.connection.quote(new_letter)} " \
                '  FROM journal_entry_items AS jei' \
                "    JOIN #{table} AS res ON (resource_id = res.id AND resource_type = #{ApplicationRecord.connection.quote(root_model)}) " \
                "  WHERE jei.account_id = #{account_id} AND jei.letter = #{ApplicationRecord.connection.quote(letter)} AND jei.printed_on > #{ApplicationRecord.connection.quote(@to_close_on)} "
          '    AND res.affair_id = affairs.id'
          Affair.connection.execute query
        end
      end
    end

    def disable_partial_lettering
      ApplicationRecord.connection.execute('ALTER TABLE journal_entry_items DISABLE TRIGGER compute_partial_lettering_status_insert_delete')
      ApplicationRecord.connection.execute('ALTER TABLE journal_entry_items DISABLE TRIGGER compute_partial_lettering_status_update')
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

      ApplicationRecord.connection.execute <<-SQL.strip_heredoc
        UPDATE journal_entry_items AS jei
          SET letter = ref.new_letter
          FROM (#{account_letterings}) AS ref
          WHERE jei.account_id = ref.account_id
            AND RTRIM(COALESCE(jei.letter, ''), '*') = ref.letter_radix
            AND letter <> ref.new_letter;
      SQL
      ApplicationRecord.connection.execute('ALTER TABLE journal_entry_items ENABLE TRIGGER compute_partial_lettering_status_insert_delete')
      ApplicationRecord.connection.execute('ALTER TABLE journal_entry_items ENABLE TRIGGER compute_partial_lettering_status_update')
    end

    def generate_closing_or_opening_entry!(journal, account_info, items, result, printed_on: @to_close_on)
      return unless journal

      account = Account.find_by(number: account_info[:number].ljust(Preference[:account_number_digits], '0'))
      account ||= Account.create!(number: account_info[:number].ljust(Preference[:account_number_digits], '0'), name: account_info[:name])

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

    #
    # Documents
    #

    def generate_documents(timing)
      @logger.info('Generate document')
      progress = Progress.new("generate_documents_#{timing}", id: @year.id, max: 6)

      if @disable_document_generation
        Rails.logger.info("Skipping document generation as they are disabled")
        return
      end

      generate_balance_documents(timing, { accounts: "", centralize: "401 411" })
      progress.increment!

      generate_balance_documents(timing, { accounts: "401", centralize: "" })
      progress.increment!

      generate_balance_documents(timing, { accounts: "411", centralize: "" })
      progress.increment!

      ['general_ledger', '401', '411'].each { |ledger| generate_general_ledger_documents(timing, { started_on: @year.started_on.to_s, stopped_on: @year.stopped_on.to_s, ledger: ledger }) }
      progress.increment!

      Journal.all.each { |journal| generate_journals_documents(timing, { journal: journal }) }
      progress.increment!

      generate_archive(timing)
      progress.increment!
    ensure
      progress.clean!
    end

    def generate_balance_documents(timing, params)
      template = DocumentTemplate.find_by_nature(:trial_balance)
      full_params = params.merge(
        states: %i[confirmed],
        started_on: @year.started_on.to_s,
        stopped_on: @year.stopped_on.to_s,
        period: "#{@year.started_on}_#{@year.stopped_on}",
        balance: "all",
        previous_year: false,
        template: template,
        levels: []
      )

      printer = Printers::TrialBalancePrinter.new(full_params)

      document = print_and_archive(template, printer)

      copy_generated_documents(timing, 'trial_balance', "#{template.nature.human_name} - #{printer.key}", document.file.path)
    end

    def print_and_archive(template, printer)
      generator = Ekylibre::DocumentManagement::DocumentGenerator.build
      archiver = Ekylibre::DocumentManagement::DocumentArchiver.build

      pdf_data = generator.generate_pdf(template: template, printer: printer)

      archiver.archive_document(pdf_content: pdf_data, template: template, key: printer.key, name: printer.document_name)
    end

    def generate_general_ledger_documents(timing, params)
      template = DocumentTemplate.find_by_nature(:general_ledger)
      printer = Printers::GeneralLedgerPrinter.new(**params.merge(template: template))

      document = print_and_archive(template, printer)

      copy_generated_documents(timing, 'general_ledger', "#{template.nature.human_name} - #{printer.key}", document.file.path)
    end

    def generate_journals_documents(timing, params)
      template = DocumentTemplate.find_by_nature(:journal_ledger)
      full_params = params.merge(
        states: %i[confirmed],
        started_on: @year.started_on.to_s,
        stopped_on: @year.stopped_on.to_s,
        period: "#{@year.started_on}_#{@year.stopped_on}",
        template: template
      )

      printer = Printers::JournalLedgerPrinter.new(full_params)

      document = print_and_archive(template, printer)

      copy_generated_documents(timing, 'journal_ledger', "#{template.nature.human_name} - #{printer.key}", document.file.path)
    end

    def copy_generated_documents(timing, nature, key, file_path)
      destination_path = Ekylibre::Tenant.private_directory.join('attachments', 'documents', 'financial_year_closures', @year.id.to_s, timing.to_s, nature.to_s, "#{key}.pdf")
      signature_path = Ekylibre::Tenant.private_directory.join('attachments', 'documents', 'financial_year_closures', @year.id.to_s, timing.to_s, nature.to_s, "#{key}.asc")
      FileUtils.mkdir_p destination_path.dirname
      FileUtils.ln file_path, destination_path
      FileUtils.ln file_path.gsub(/\.pdf/, '.asc'), signature_path
    end

    def generate_archive(timing)
      zip_path = Ekylibre::Tenant.private_directory.join('attachments', 'documents', 'financial_year_closures', @year.id.to_s, "#{@year.id}_#{timing}.zip")
      file_path = Ekylibre::Tenant.private_directory.join('attachments', 'documents', 'financial_year_closures', @year.id.to_s)
      begin
        Zip::File.open(zip_path, Zip::File::CREATE) do |zip|
          Dir[File.join(file_path, "#{timing}/**/**")].each do |file|
            zip.add(file.sub("#{file_path}/", ''), file)
          end
        end
      end

      sha256 = Digest::SHA256.file zip_path
      crypto = GPGME::Crypto.new
      signature = crypto.clearsign(sha256.to_s, signer: ENV['GPG_EMAIL'])
      signature_path = Ekylibre::Tenant.private_directory.join('attachments', 'documents', 'financial_year_closures', @year.id.to_s, "#{@year.id}_#{timing}.asc")
      File.write(signature_path, signature)
      @year.archives.create!(timing: timing, sha256_fingerprint: sha256.to_s, signature: signature.to_s, path: zip_path)
    end

    def dump_tenant
      # @year state will be set to 'closing' when restoring this dump, think about updating it to 'opened'
      tenant = Ekylibre::Tenant.current
      @logger.info("Dump #{tenant.to_s}")
      dump_path = Ekylibre::Tenant.private_directory.join('prior_to_closure_dump')
      FileUtils.mkdir_p dump_path
      @logger.info("Create folder in #{dump_path.to_s}")
      Dir.mktmpdir do |dir|
        Ekylibre::Tenant.dump(tenant, path: Pathname.new(dir))
        FileUtils.mv "#{dir}/#{tenant}.zip", dump_path
      end
    end
end
