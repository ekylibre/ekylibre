require 'test_helper'

class FinancialYearCloseTest < Ekylibre::Testing::ApplicationTestCase
  setup do
    FileUtils.rm_rf Ekylibre::Tenant.private_directory.join('tmp', 'imports')

    @today = Date.new(2019, 3, 15)
    @dumpster_account = Account.create!(name: 'TestDumpster', number: '10001')
    @dumpster_journal = Journal.create!(name: 'Dumpster journal', code: 'DMPTST')
    @beginning = (@today - 1.month).beginning_of_month
    @end = (@today - 1.month).end_of_month
    @year = FinancialYear.create!(started_on: @beginning, stopped_on: @end)
    @next_year = FinancialYear.create!(started_on: @today.beginning_of_month, stopped_on: @today.end_of_month)
    @profits = Account.create!(name: 'FinancialYear result profit', number: '120', usages: :financial_year_result_profit)
    @losses = Account.create!(name: 'FinancialYear result loss', number: '129', usages: :financial_year_result_loss)

    @open = Account.create!(number: '89', name: 'Opening account')
    @close = Account.create!(number: '891', name: 'Closing account')
    @closer = create(:user)

    templates = [['trial_balance', 'Balance comptable'], ['general_ledger', 'Grand livre'], ['journal_ledger', 'Etat du journal']]
    templates.each do |nature, name|
      DocumentTemplate.create!(nature: nature, name: name, language: 'fra', managed: true, signed: true)
    end
  end

  teardown do
    FileUtils.rm_rf Ekylibre::Tenant.private_directory.join('attachments', 'documents', 'financial_year_closures', "#{@year.id}")
    FileUtils.rm_rf Ekylibre::Tenant.private_directory.join('prior_to_closure_dump')
  end

  test 'products and expenses balance' do
    result = Journal.create!(name: 'Results TEST', code: 'RSTST', nature: :result)

    accounts = {
      7030 => Account.find_or_import_from_nomenclature(:processing_products_revenues),
      5110 => Account.find_or_import_from_nomenclature(:pending_deposit_payments),
      6028 => Account.find_or_import_from_nomenclature(:raw_material_expenses),
      5120 => Account.find_or_import_from_nomenclature(:banks),
      4552 => Account.find_or_import_from_nomenclature(:usual_associates_current_accounts)
    }

    generate_entry(accounts[4552], 60, destination_account: accounts[7030])
    generate_entry(accounts[5110], 60, destination_account: accounts[4552])
    generate_entry(accounts[6028], 20, destination_account: accounts[4552])
    generate_entry(accounts[4552], 20, destination_account: accounts[5120])

    validate_fog

    close = FinancialYearClose.new(@year, @year.stopped_on, @closer, result_journal: result, disable_document_generation: true)
    assert close.execute, close.close_error

    assert_equal 5, JournalEntry.count
    assert_equal 0, accounts[7030].journal_entry_items.sum('debit - credit')
    assert_equal 0, accounts[6028].journal_entry_items.sum('debit - credit')
    assert_equal 0, accounts[4552].journal_entry_items.sum('debit - credit')
    assert_equal 40, @profits.journal_entry_items.sum('credit - debit')
  end

  test 'Carry-forward letterable items' do
    result = Journal.create!(name: 'Results TEST', code: 'RSTST', nature: :result)
    closing = Journal.create!(name: 'Close TEST', code: 'CLOSTST', nature: :closure)
    forward = Journal.create!(name: 'Forward TEST', code: 'FWDTST', nature: :forward)
    test_accounts = [
      nil,
      Account.create!(name: 'Test1x', number: '1222'),
      Account.create!(name: 'Test2x', number: '2111'),
      Account.create!(name: 'Test3x', number: '3414'),
      Account.create!(name: 'Test4x', number: '4313')
    ]

    generate_entry(test_accounts[1], 2000)
    generate_entry(test_accounts[1], 300)
    generate_entry(test_accounts[2], -3000)
    generate_entry(test_accounts[2], -465)
    generate_entry(test_accounts[3], 200)
    generate_entry(test_accounts[3], 1730)
    generate_entry(test_accounts[4], -465)
    generate_entry(test_accounts[4], -300)
    validate_fog

    close = FinancialYearClose.new(
      @year, @year.stopped_on, @closer,
      result_journal: result,
      closure_journal: closing,
      forward_journal: forward,
      allocations: {},
      disable_document_generation: true
    )

    assert close.execute, close.close_error

    assert_equal 10, @year.journal_entries.count

    test_accounts[1..4].each do |account|
      original_amount = account.journal_entry_items.order(:id).to_a[0..1].sum(&:balance)
      this_years = account.journal_entry_items.where(financial_year: @year)
      next_years = account.journal_entry_items.where(financial_year: @year.next)
      assert_equal 3, this_years.count
      assert_equal 1, next_years.count

      assert_equal 0, this_years.sum('debit - credit')
      assert_equal original_amount, next_years.sum('debit - credit')
    end
  end

  test 'lettered carry forward' do
    Entity.of_company.update!(legal_position_code: "EI")
    result = Journal.create!(name: 'Results TEST', code: 'RSTST', nature: :result)
    closing = Journal.create!(name: 'Close TEST', code: 'CLOSTST', nature: :closure)
    forward = Journal.create!(name: 'Forward TEST', code: 'FWDTST', nature: :forward)

    @credit_carry_forward = Account.create!(name: 'credit carry forward', number: '110', usages: :credit_retained_earnings)
    @debit_carry_forward = Account.create!(name: 'debit carry forward', number: '119', usages: :debit_retained_earnings)

    test_accounts = {
      101 => Account.create!(name: 'Test1x', number: '101'),
      110 => @credit_carry_forward,
      119 => @debit_carry_forward,
      4 => Account.create!(name: 'Test4x', number: '45521'),
      5 => Account.create!(name: 'Test5x', number: '511'),
      7 => Account.create!(name: 'Test7x', number: '707')
    }

    letter = test_accounts[4].new_letter
    this_years = {
      300 => generate_entry(test_accounts[4], 500, letter: letter, destination_account: test_accounts[7]),
      500 => generate_entry(test_accounts[4], 300, letter: letter, destination_account: test_accounts[7])
    }
    next_years = generate_entry(test_accounts[4], -800, letter: letter, printed_on: @end + 2.days, destination_account: test_accounts[5])
    validate_fog

    close = FinancialYearClose.new(
      @year, @year.stopped_on, @closer,
      result_journal: result,
      closure_journal: closing,
      forward_journal: forward,
      allocations: { '101' => 800 },
      disable_document_generation: true
    )

    assert close.execute, close.close_error

    assert_equal 6, @year.journal_entries.count
    assert_equal 5, @next_year.journal_entries.count

    assert_equal 3, @close.journal_entry_items.count
    assert_equal 3, @open.journal_entry_items.count

    this_years.each do |_amount, entry|
      item = entry.items.where.not(letter: nil).first

      assert_equal letter + '*', item.letter
      assert_equal 800, item.letter_group.sum('debit - credit')

      assert_not_empty @close.journal_entry_items.where(debit: item.debit, credit: item.credit)
      assert_not_empty @open.journal_entry_items.where(debit: item.credit, credit: item.debit)
    end

    next_years_lettered_item = next_years.items.where.not(letter: nil).first

    assert_not_equal letter, next_years_lettered_item.letter
    assert_equal 0, next_years_lettered_item.letter_group.sum('debit - credit')

    next_years_matching = matching_lettered_item(next_years_lettered_item)

    assert_equal test_accounts[4], next_years_matching.account
    assert_equal @open, complementary_in_entry_of(next_years_matching).account
  end

  test 'closure raises an error if balance sheet is unbalanced' do
    result = Journal.create!(name: 'Results TEST', code: 'RSTST', nature: :result)

    test_accounts = {
      6012 => Account.create!(name: 'Test6x', number: '6012'),
      6063 => Account.create!(name: 'Test6x2', number: '6063')
    }

    generate_entry(test_accounts[6012], 5000)
    generate_entry(test_accounts[6063], -3000)

    validate_fog

    close = FinancialYearClose.new(
      @year, @year.stopped_on, @closer,
      result_journal: result,
      disable_document_generation: true
    )

    assert_not close.execute
  end

  test 'allocate results' do
    Entity.of_company.update!(legal_position_code: "SA")
    result = Journal.create!(name: 'Results TEST', code: 'RSTST', nature: :result)
    closing = Journal.create!(name: 'Close TEST', code: 'CLOSTST', nature: :closure)
    forward = Journal.create!(name: 'Forward TEST', code: 'FWDTST', nature: :forward)

    test_accounts = {
      1061 => Account.create!(name: 'Test1061x', number: '1061'),
      1063 => Account.create!(name: 'Test1063x', number: '1063'),
      1064 => Account.create!(name: 'Test1064x', number: '1064'),
      1068 => Account.create!(name: 'Test1068x', number: '1068'),
      457 => Account.create!(name: 'Test457x', number: '457'),
      4423 => Account.create!(name: 'Test4423x', number: '4423'),
      110 => Account.create!(name: 'Test110x', number: '110')
    }

    accounts = {
      7030 => Account.find_or_import_from_nomenclature(:processing_products_revenues),
      5110 => Account.find_or_import_from_nomenclature(:pending_deposit_payments),
      6028 => Account.find_or_import_from_nomenclature(:raw_material_expenses),
      5120 => Account.find_or_import_from_nomenclature(:banks),
      4552 => Account.find_or_import_from_nomenclature(:usual_associates_current_accounts)
    }

    generate_entry(accounts[4552], 2000, destination_account: accounts[7030])
    generate_entry(accounts[5110], 2000, destination_account: accounts[4552])
    generate_entry(accounts[6028], 300, destination_account: accounts[4552])
    generate_entry(accounts[4552], 300, destination_account: accounts[5120])

    validate_fog

    allocations = {
      '1061' => 150,
      '1063' => 150,
      '1064' => 150,
      '1068' => 150,
      '457' => 400,
      '4423' => 300,
      '110' => 400,
    }

    assert_equal 1700, allocations.values.reduce(&:+)

    close = FinancialYearClose.new(
      @year, @year.stopped_on, User.first,
      allocations: allocations,
      result_journal: result,
      closure_journal: closing,
      forward_journal: forward,
      disable_document_generation: true
    )

    assert close.execute, close.close_error
    assert_equal 7, @year.journal_entries.count
    assert_equal 150, test_accounts[1061].totals[:balance].to_f
    assert_equal 150, test_accounts[1063].totals[:balance].to_f
    assert_equal 400, test_accounts[457].totals[:balance].to_f
    assert_equal 400, test_accounts[110].totals[:balance].to_f
  end

  private

    def generate_entry(account, debit, letter: nil, printed_on: @beginning + 2.days, destination_account: @dumpster_account)
      return if debit.zero?
      side = debit > 0 ? :debit : :credit
      other_side = debit < 0 ? :debit : :credit
      amount = debit.abs
      JournalEntry.create!(
        journal: @dumpster_journal,
        printed_on: printed_on,
        items_attributes: [
          {
            name: side.to_s.capitalize,
            account: account,
            letter: letter,
            :"real_#{side}" => amount
          },
          {
            name: other_side.to_s.capitalize,
            account: destination_account,
            :"real_#{other_side}" => amount
          }
        ]
      )
    end

    def validate_fog
      @year.journal_entries.find_each { |je| je.update(state: :confirmed) }
    end

    def matching_lettered_item(item)
      (item.letter_group - [item]).first
    end

    def complementary_in_entry_of(item)
      (item.entry.items - [item]).first
    end
end
