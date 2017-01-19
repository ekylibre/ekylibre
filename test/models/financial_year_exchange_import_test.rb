require 'test_helper'

class FinancialYearExchangeImportTest < ActiveSupport::TestCase
  def define_context
    accountant = create(:entity, :accountant)

    financial_year = financial_years(:financial_years_025)
    assert financial_year.update_attribute(:accountant_id, accountant.id)

    booked_journal = create(:journal, :various, code: 'JCR', accountant_id: accountant.id)
    account = create(:account)

    entry_in_financial_year = create(:journal_entry, :confirmed, :with_items, journal: booked_journal, printed_on: financial_year.started_on + 1.day)
    entry_out_of_financial_year = create(:journal_entry, :confirmed, :with_items, journal: booked_journal, printed_on: financial_year.stopped_on + 1.day)

    exchange = create(:financial_year_exchange, :opened, financial_year: financial_year)

    @context = {
      account: create(:account, number: '8001000000001'),
      accountant: accountant,
      booked_journal: booked_journal,
      financial_year: financial_year,
      financial_year_exchange: exchange
    }
  end

  def account
    @context[:account]
  end

  def financial_year
    @context[:financial_year]
  end

  def financial_year_exchange
    @context[:financial_year_exchange]
  end

  def booked_journal
    @context[:booked_journal]
  end

  def financial_year
    @context[:financial_year]
  end

  test 'run fails when the file is invalid' do
    define_context
    invalid_file = File.open(fixture_file('financial_year_exchange_import_invalid.csv'))
    import = FinancialYearExchangeImport.new(invalid_file, financial_year_exchange)
    refute import.run
    assert import.error.present?
    assert import.error.is_a?(FinancialYearExchangeImport::InvalidFile)
  end

  test 'run fails when the file headers does not match the expected ones' do
    define_context
    invalid_file = File.open(fixture_file('financial_year_exchange_import_invalid_headers.csv'))
    import = FinancialYearExchangeImport.new(invalid_file, financial_year_exchange)
    refute import.run
    assert import.error.present?
    assert import.error.is_a?(FinancialYearExchangeImport::InvalidFile)
  end

  test 'run fails when the file contains a nonexistant journal' do
    define_context
    invalid_file = File.open(fixture_file('financial_year_exchange_import_nonexistant_journal.csv'))
    import = FinancialYearExchangeImport.new(invalid_file, financial_year_exchange)
    refute import.run
    assert import.error.present?
    assert import.error.is_a?(FinancialYearExchangeImport::InvalidFile)
  end

  test 'run fails when the file contains entries with printed on out of financial year range' do
    define_context
    invalid_file = File.open(fixture_file('financial_year_exchange_import_entry_date_invalid.csv'))
    import = FinancialYearExchangeImport.new(invalid_file, financial_year_exchange)
    refute import.run
    assert import.error.present?
    assert import.error.is_a?(FinancialYearExchangeImport::InvalidFile)
  end

  test 'run fails when the file contains entries with printed on unparsable' do
    define_context
    invalid_file = File.open(fixture_file('financial_year_exchange_import_entry_date_unparsable.csv'))
    import = FinancialYearExchangeImport.new(invalid_file, financial_year_exchange)
    refute import.run
    assert import.error.present?
    assert import.error.is_a?(FinancialYearExchangeImport::InvalidFile)
  end
  test 'does not destroy any journal entries when run fails due to invalid balance on a specific entry' do
    define_context
    journal_entry_ids = booked_journal.entries.map(&:id)
    file = File.open(fixture_file('financial_year_exchange_import_balance_invalid.csv'))
    import = FinancialYearExchangeImport.new(file, financial_year_exchange)
    refute import.run
    assert_equal journal_entry_ids.length, JournalEntry.where(id: journal_entry_ids).count
  end

  test 'does not create journal entries when run fails due to invalid balance on a specific entry' do
    define_context
    journal_entry_ids = booked_journal.entries.map(&:id)
    file = File.open(fixture_file('financial_year_exchange_import_balance_invalid.csv'))
    import = FinancialYearExchangeImport.new(file, financial_year_exchange)
    refute import.run
    assert_equal journal_entry_ids.length, JournalEntry.where(id: journal_entry_ids).count
  end

  test 'does not store the file when run fails due to invalid balance on a specific entry' do
    define_context
    file = File.open(fixture_file('financial_year_exchange_import_balance_invalid.csv'))
    import = FinancialYearExchangeImport.new(file, financial_year_exchange)
    refute import.run
    refute financial_year_exchange.reload.import_file.exists?
  end
  test 'destroy journal entries in journal booked by the accountant in the same financial year' do
    define_context
    file = File.open(fixture_file('financial_year_exchange_import.csv'))
    journal_entry_ids = booked_journal.entries.select { |e| e.financial_year == financial_year }.map(&:id)
    import = FinancialYearExchangeImport.new(file, financial_year_exchange)
    assert import.run
    assert_equal 0, JournalEntry.where(id: journal_entry_ids).count
  end

  test 'does not destroy journal entries in journal booked by the accountant in different financial year' do
    define_context
    file = File.open(fixture_file('financial_year_exchange_import.csv'))
    journal_entry_ids = booked_journal.entries.select { |e| e.financial_year != financial_year }.map(&:id)
    import = FinancialYearExchangeImport.new(file, financial_year_exchange)
    assert import.run
    assert_equal journal_entry_ids.length, JournalEntry.where(id: journal_entry_ids).count
  end

  test 'creates journal entries in journal booked by the accountant' do
    define_context
    file = File.open(fixture_file('financial_year_exchange_import.csv'))
    import = FinancialYearExchangeImport.new(file, financial_year_exchange)

    assert import.run
    created_entry = booked_journal.entries.detect { |e| e.number == '12345' }
    assert created_entry.present?
    assert created_entry.closed?
    assert_equal Date.parse('2015-09-02'), created_entry.printed_on
    assert_equal 2, created_entry.items.length

    item1 = created_entry.items.detect { |i| i.name == 'Ecriture1' }
    assert item1.present?
    assert_equal "12.5", item1.real_debit.to_s
    assert_equal "0.0", item1.real_credit.to_s
    assert_equal account.id, item1.account_id
    assert_equal Date.parse("2015-09-02"), item1.printed_on

    item2 = created_entry.items.detect { |i| i.name == 'Ecriture2' }
    assert item2.present?
    assert_equal "0.0", item2.real_debit.to_s
    assert_equal "12.5", item2.real_credit.to_s
    assert_equal account.id, item2.account_id
    assert_equal Date.parse("2015-09-02"), item2.printed_on
  end

  test 'store the file' do
    define_context
    file = File.open(fixture_file('financial_year_exchange_import.csv'))
    assert financial_year_exchange.import_file.blank?
    import = FinancialYearExchangeImport.new(file, financial_year_exchange)
    assert import.run
    financial_year_exchange.reload
    assert_equal financial_year_exchange.import_file.size, file.size
  end
end
