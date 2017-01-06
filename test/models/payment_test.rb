require 'test_helper'

# Ensures letter_with behaviour mainly + that sign_of_amounts are properly balanced.
class PaymentTest < ActiveSupport::TestCase
  test 'ensure sign of amount is different in Incoming and Outgoing payments' do
    assert_equal 0, IncomingPayment.sign_of_amount + OutgoingPayment.sign_of_amount
  end

  [IncomingPayment, OutgoingPayment].each do |payment|
    test "#{payment} can be lettered with bank_statement_items" do
      @payment_class = payment
      setup_data
      assert_lettered_by @payment.letter_with(@tanks), with_letters: %w(A)
    end

    test "#{payment} cannot be lettered when amounts don't match" do
      @payment_class = payment
      setup_data(amount_mismatch: true)
      assert_not_lettered_by @payment.letter_with(@tanks)
    end

    test "#{payment} cannot be lettered when the payment doesn't have any journal entry" do
      @payment_class = payment
      setup_data(no_journal_entry: true)
      assert_not_lettered_by @payment.letter_with(@tanks)
    end

    test "#{payment} cannot be lettered when there's the cashes don't match" do
      @payment_class = payment
      setup_data(cash_mismatch: true)
      assert_not_lettered_by @payment.letter_with(@tanks)
    end

    test "#{payment} cannot be lettered without any bank statement items" do
      @payment_class = payment
      setup_data
      assert_not_lettered_by @payment.letter_with([])
    end
  end

  def assert_lettered_by(operation, with_letters: ['A'])
    assert operation
    assert_equal with_letters,
                 @payment.journal_entry.items.pluck(:bank_statement_letter).uniq.compact
    assert_equal with_letters,
                 @tanks.each(&:reload).map(&:letter).uniq
  end

  def assert_not_lettered_by(operation)
    refute operation
    if @payment.journal_entry
      assert_empty @payment.journal_entry.items.pluck(:bank_statement_letter).uniq.compact
    end
    assert_empty @tanks.map(&:letter).uniq.compact
  end

  def wipe_db
    Journal.delete_all
    Account.delete_all
    Cash.delete_all
    BankStatement.delete_all
    BankStatementItem.delete_all
    Entity.delete_all
    IncomingPayment.delete_all
    IncomingPaymentMode.delete_all
    OutgoingPayment.delete_all
    OutgoingPaymentMode.delete_all
  end

  def setup_data(**options)
    wipe_db

    ::Preference.set!(:bookkeep_automatically, options[:no_journal_entry].blank?)
    journal     = Journal.create!
    fuel_act    = Account.create!(name: 'Fuel', number: '002')
    caps_act    = Account.create!(name: 'Caps', number: '001')

    @warrig_tank = Cash.create!(journal: journal, main_account: fuel_act, name: 'War-rig\'s Tank')
    @caps_stash  = Cash.create!(journal: journal, main_account: caps_act, name: 'Stash o\' Caps')

    setup_items(options[:amount_mismatch] ? 1336 : 1337)
    setup_payment(options[:cash_mismatch])
  end

  def setup_items(amount)
    amount_attr = (@payment_class == IncomingPayment ? :credit : :debit)

    now = Time.zone.now
    fuel_level = BankStatement.create!(
      currency: 'EUR',
      number: 'Fuel level check',
      started_on: now - 10.days,
      stopped_on: now,
      cash: @warrig_tank
    )

    @tanks =  []
    @tanks << BankStatementItem.create!(
      name: 'Main tank',
      bank_statement: fuel_level,
      transfered_on: now - 5.days,
      amount_attr => 42
    )

    @tanks << BankStatementItem.create!(
      name: 'Backup tank',
      bank_statement: fuel_level,
      transfered_on: now - 5.days,
      amount_attr => amount
    )
  end

  def setup_payment(cash_match)
    cash = cash_match ? @caps_stash : @warrig_tank

    Account.create!(name: 'Citadel', number: '6')

    diesel      = "#{@payment_class}Mode".constantize.create!(cash: cash, with_accounting: true, name: 'Diesel')
    max         = Entity.create!(first_name: 'Max', last_name: 'Rockatansky', nature: :contact)
    @payment    = @payment_class.create!(amount: 1379, currency: 'EUR', @payment_class.third_attribute => max, mode: diesel, responsible: User.first, to_bank_at: Time.zone.now - 5.days)
  end
end
