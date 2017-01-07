require 'test_helper'

class FinancialYearExchangeImportTest < ActiveSupport::TestCase
  test 'run fails when the file is invalid' do
    invalid_file = File.open(fixture_file('financial_year_exchange_import_invalid.csv'))
    exchange = financial_year_exchanges(:financial_year_exchanges_001)
    import = FinancialYearExchangeImport.new(invalid_file, exchange)
    refute import.run
    assert import.error.present?
    assert import.error.is_a?(FinancialYearExchangeImport::InvalidFile)
  end

  test 'run fails when the file headers does not match the expected ones' do
    invalid_file = File.open(fixture_file('financial_year_exchange_import_invalid_headers.csv'))
    exchange = financial_year_exchanges(:financial_year_exchanges_001)
    import = FinancialYearExchangeImport.new(invalid_file, exchange)
    refute import.run
    assert import.error.present?
    assert import.error.is_a?(FinancialYearExchangeImport::InvalidFile)
  end

  test 'run fails when the file contains a nonexistant journal' do
    invalid_file = File.open(fixture_file('financial_year_exchange_import_nonexistant_journal.csv'))
    exchange = financial_year_exchanges(:financial_year_exchanges_001)
    import = FinancialYearExchangeImport.new(invalid_file, exchange)
    refute import.run
    assert import.error.present?
    assert import.error.is_a?(FinancialYearExchangeImport::InvalidFile)
  end

  test 'run fails when the file contains entries with printed on out of financial year range' do
    invalid_file = File.open(fixture_file('financial_year_exchange_import_entry_date_invalid.csv'))
    exchange = financial_year_exchanges(:financial_year_exchanges_001)
    import = FinancialYearExchangeImport.new(invalid_file, exchange)
    refute import.run
    assert import.error.present?
    assert import.error.is_a?(FinancialYearExchangeImport::InvalidFile)
  end

  test 'run fails when the file contains entries with printed on unparsable' do
    invalid_file = File.open(fixture_file('financial_year_exchange_import_entry_date_unparsable.csv'))
    exchange = financial_year_exchanges(:financial_year_exchanges_001)
    import = FinancialYearExchangeImport.new(invalid_file, exchange)
    refute import.run
    assert import.error.present?
    assert import.error.is_a?(FinancialYearExchangeImport::InvalidFile)
  end

  test 'does not destroy any journal entries when run fails due to invalid balance on a specific entry' do
    file = File.open(fixture_file('financial_year_exchange_import_balance_invalid.csv'))
    exchange = financial_year_exchanges(:financial_year_exchanges_001)
    journal = journals(:journals_010)
    journal_entry_numbers = journal.entries.map(&:number)
    import = FinancialYearExchangeImport.new(file, exchange)
    refute import.run
    journal.entries.reload
    assert_equal journal_entry_numbers, journal.entries.map(&:number)
  end

  test 'does not create journal entries when run fails due to invalid balance on a specific entry' do
    file = File.open(fixture_file('financial_year_exchange_import_balance_invalid.csv'))
    exchange = financial_year_exchanges(:financial_year_exchanges_001)
    import = FinancialYearExchangeImport.new(file, exchange)
    refute import.run
    journal = journals(:journals_010)
    refute journal.entries.detect { |e| e.number == '12345' }.present?
  end

  test 'does not store the file when run fails due to invalid balance on a specific entry' do
    file = File.open(fixture_file('financial_year_exchange_import_balance_invalid.csv'))
    exchange = financial_year_exchanges(:financial_year_exchanges_001)
    import = FinancialYearExchangeImport.new(file, exchange)
    refute import.run
    exchange.reload
    refute exchange.import_file.exists?
  end

  test 'destroy journal entries in journal booked by the accountant in the same financial year' do
    file = File.open(fixture_file('financial_year_exchange_import.csv'))
    exchange = financial_year_exchanges(:financial_year_exchanges_001)
    journal_entry = journals(:journals_010).entries.sample
    journal_entry.update_column :printed_on, exchange.financial_year.started_on + 1.day
    import = FinancialYearExchangeImport.new(file, exchange)
    assert import.run
    assert_raises(ActiveRecord::RecordNotFound) { journal_entry.reload }
  end

  test 'does not destroy journal entries in journal booked by the accountant in different financial year' do
    file = File.open(fixture_file('financial_year_exchange_import.csv'))
    exchange = financial_year_exchanges(:financial_year_exchanges_001)
    journal_entry = journals(:journals_010).entries.sample
    journal_entry.update_column :printed_on, exchange.financial_year.started_on - 1.day
    import = FinancialYearExchangeImport.new(file, exchange)
    assert import.run
    journal_entry.reload # should not raise
  end

  test 'creates journal entries in journal booked by the accountant' do
    file = File.open(fixture_file('financial_year_exchange_import.csv'))
    exchange = financial_year_exchanges(:financial_year_exchanges_001)
    import = FinancialYearExchangeImport.new(file, exchange)

    assert import.run!, 'Import fails'
    journal = journals(:journals_010)
    created_entry = journal.entries.detect { |e| e.number == '12345' }
    assert created_entry.present?
    assert created_entry.closed?
    assert_equal Date.parse('2015-09-02'), created_entry.printed_on
    assert_equal 2, created_entry.items.length

    item1 = created_entry.items.detect { |i| i.name == 'Ecriture1' }
    assert item1.present?
    assert_equal '12.5', item1.real_debit.to_s
    assert_equal '0.0', item1.real_credit.to_s
    assert_equal accounts(:accounts_324).id, item1.account_id
    assert_equal Date.parse('2015-09-02'), item1.printed_on

    item2 = created_entry.items.detect { |i| i.name == 'Ecriture2' }
    assert item2.present?
    assert_equal '0.0', item2.real_debit.to_s
    assert_equal '12.5', item2.real_credit.to_s
    assert_equal accounts(:accounts_324).id, item2.account_id
    assert_equal Date.parse('2015-09-02'), item2.printed_on
  end

  test 'store the file' do
    file = File.open(fixture_file('financial_year_exchange_import.csv'))
    exchange = financial_year_exchanges(:financial_year_exchanges_001)
    assert exchange.import_file.blank?
    import = FinancialYearExchangeImport.new(file, exchange)
    assert import.run!, 'Import fails'
    exchange.reload
    assert_equal exchange.import_file.size, file.size
  end
end
