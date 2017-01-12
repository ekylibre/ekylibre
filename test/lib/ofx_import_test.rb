require 'test_helper'

class OfxImportTest < ActiveSupport::TestCase
  test 'run fails when the OFX is invalid' do
    invalid_file = open_fixture_file('ofx_invalid.ofx')
    cash = cashes(:cashes_003)
    import = OfxImport.new(invalid_file, cash)
    assert !import.run
    assert import.error.present?
    assert OfxImport::InvalidOfxFile === import.error
    assert import.internal_error.present?
    assert !import.recoverable?
  end

  test 'run fails when the OFX has multiple bank accounts' do
    file = open_fixture_file('ofx_multiple_bank_accounts.ofx')
    cash = cashes(:cashes_003)
    import = OfxImport.new(file, cash)
    assert !import.run
    assert import.error.present?
    assert OfxImport::OfxFileHasMultipleAccounts === import.error
    assert !import.recoverable?
  end

  test 'run fails but is recoverable when the OFX statement has more than 99 days' do
    file = open_fixture_file('ofx_more_than_99_days.ofx')
    cash = cashes(:cashes_003)
    import = OfxImport.new(file, cash)
    assert !import.run
    assert import.error.present?
    assert import.recoverable?
    assert import.bank_statement.present?
  end

  test 'run succeeds' do
    file = open_fixture_file('ofx_valid.ofx')
    cash = cashes(:cashes_003)
    import = OfxImport.new(file, cash)
    assert import.run
    assert_nil import.error

    bank_statement = import.bank_statement
    assert bank_statement.valid?
    assert bank_statement.persisted?
    assert_equal cash.id, bank_statement.cash_id
    assert_equal '2016040138', bank_statement.number
    assert_equal '2016-04-01', bank_statement.started_on.to_s
    assert_equal '2016-05-09', bank_statement.stopped_on.to_s
    assert_equal 1, bank_statement.items.length

    item = bank_statement.items.take
    assert item.valid?
    assert item.persisted?
    assert_equal 'PRLV SEPA MUTUELLE 123', item.name
    assert_equal '201600400001AB12', item.transaction_number
    assert_equal '2016-05-09', item.transfered_on.to_s
    assert_equal '2016-05-10', item.initiated_on.to_s
    assert_equal 34.56, item.debit
  end

  test 'run succeeds with non-UTF8 file' do
    file = open_fixture_file('ofx_non_utf8.ofx')
    cash = cashes(:cashes_003)
    import = OfxImport.new(file, cash)
    assert import.run
    assert_nil import.error

    bank_statement = import.bank_statement
    assert bank_statement.valid?
    assert bank_statement.persisted?
    assert_equal cash.id, bank_statement.cash_id
    assert_equal '2016040138', bank_statement.number
    assert_equal Date.parse('2016-04-01'), bank_statement.started_on
    assert_equal Date.parse('2016-05-09'), bank_statement.stopped_on
    assert_equal 1, bank_statement.items.length

    item = bank_statement.items.take
    assert item.valid?
    assert item.persisted?
    assert_equal 'PRLV SEPA MUTUELLE N°123', item.name
    assert_equal '201600400001AB12', item.transaction_number
    assert_equal Date.parse('2016-05-09'), item.transfered_on
    assert_equal 34.56, item.debit
  end

  test 'run succeeds without LEDGERBAL' do
    file = open_fixture_file('ofx_without_ledgerbal.ofx')
    cash = cashes(:cashes_003)
    import = OfxImport.new(file, cash)
    assert import.run
    assert_nil import.error

    bank_statement = import.bank_statement
    assert bank_statement.valid?
    assert bank_statement.persisted?
    assert_equal cash.id, bank_statement.cash_id
    assert_equal '2016040138', bank_statement.number
    assert_equal '2016-04-01', bank_statement.started_on.to_s
    assert_equal '2016-05-09', bank_statement.stopped_on.to_s
    assert_equal 1, bank_statement.items.length

    item = bank_statement.items.take
    assert item.valid?
    assert item.persisted?
    assert_equal 'PRLV SEPA MUTUELLE 123', item.name
    assert_equal '201600400001AB12', item.transaction_number
    assert_equal '2016-05-09', item.transfered_on.to_s
    assert_equal '2016-05-10', item.initiated_on.to_s
    assert_equal 34.56, item.debit
  end

  test 'run succeeds without newline' do
    file = open_fixture_file('ofx_without_newlines.ofx')
    cash = cashes(:cashes_003)
    import = OfxImport.new(file, cash)
    assert import.run
    assert_nil import.error

    bank_statement = import.bank_statement
    assert bank_statement.valid?
    assert bank_statement.persisted?
    assert_equal cash.id, bank_statement.cash_id
    assert_equal '2016040138', bank_statement.number
    assert_equal '2016-04-01', bank_statement.started_on.to_s
    assert_equal '2016-05-09', bank_statement.stopped_on.to_s
    assert_equal 1, bank_statement.items.length

    item = bank_statement.items.take
    assert item.valid?
    assert item.persisted?
    assert_equal 'PRLV SEPA MUTUELLE 123', item.name
    assert_equal '201600400001AB12', item.transaction_number
    assert_equal '2016-05-09', item.transfered_on.to_s
    assert_equal 34.56, item.debit
  end

  def open_fixture_file(path)
    file = fixture_file(path)
    File.open file
  end
end
