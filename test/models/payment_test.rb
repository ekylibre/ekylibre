require 'test_helper'

class PaymentTest < ActiveSupport::TestCase
  test 'ensure sign of amount is different in Incoming and Outgoing payments' do
    assert_equal 0, IncomingPayment.sign_of_amount + OutgoingPayment.sign_of_amount
  end

  [IncomingPayment, OutgoingPayment].each do |payment|
    test "#{payment} can be lettered with bank_statement_items" do
      set_up(payment)

      assert @payment.letter_with(@tanks)
      assert_equal ['A'], @payment.journal_entry.items.pluck(:bank_statement_letter).uniq.compact
      assert_equal ['A'], @tanks.each(&:reload).map(&:letter).uniq
    end

    test "#{payment} cannot be lettered when amounts don't match" do
      set_up(payment, amount_mismatch: true)

      refute @payment.letter_with(@tanks)
      assert_empty @payment.journal_entry.items.pluck(:bank_statement_letter).uniq.compact
      assert_empty @tanks.map(&:letter).uniq.compact
    end

    test "#{payment} cannot be lettered when the payment doesn't have any journal entry" do
      set_up(payment, no_journal_entry: true)

      refute @payment.letter_with(@tanks)
      refute @payment.journal_entry
      assert_empty @tanks.map(&:letter).uniq.compact
    end

    test "#{payment} cannot be lettered when there's the cashes don't match" do
      set_up(payment, cash_mismatch: true)

      refute @payment.letter_with(@tanks)
      assert_empty @payment.journal_entry.items.pluck(:bank_statement_letter).uniq.compact
      assert_empty @tanks.map(&:letter).uniq.compact
    end

    test "#{payment} cannot be lettered without any bank statement items" do
      set_up(payment)

      refute @payment.letter_with([])
      assert_empty @payment.journal_entry.items.pluck(:bank_statement_letter).uniq.compact
      assert_empty @tanks.map(&:letter).uniq.compact
    end
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

  def set_up(payment_class, **options)
    wipe_db

    ::Preference.set!(:bookkeep_automatically, options[:no_journal_entry].blank?)

    cred_deb = payment_class == IncomingPayment ? :debit : :credit

    journal     = Journal.create!
    caps_act    = Account.create!(name: 'Caps', number: '001')
    fuel_act    = Account.create!(name: 'Fuel', number: '002')
    Account.create!(name: 'Citadel', number: '6')
    caps_stash  = Cash.create!(journal: journal, main_account: caps_act, name: 'Stash o\' Caps')
    warrig_tank = Cash.create!(journal: journal, main_account: fuel_act, name: 'War-rig\'s Tank')

    fuel_level  = BankStatement.create!(currency: 'EUR', number: 'Fuel level check', started_on: Time.zone.now - 10.days, stopped_on: Time.zone.now, cash: warrig_tank)
    @tanks      = []
    @tanks     << BankStatementItem.create!(
                    name: 'Main tank',
                    bank_statement: fuel_level,
                    transfered_on: Time.zone.now - 5.days,
                    cred_deb => 42
                  )
    @tanks     << BankStatementItem.create!(
                    name: 'Backup tank',
                    bank_statement: fuel_level,
                    transfered_on: Time.zone.now - 5.days,
                    cred_deb => options[:amount_mismatch] ? 1336 : 1337
                  )

    cash = options[:cash_mismatch] ? caps_stash : warrig_tank
    diesel      = "#{payment_class}Mode".constantize.create!(cash: cash, with_accounting: true, name: 'Diesel')
    max         = Entity.create!(first_name: 'Max', last_name: 'Rockatansky', nature: :contact)
    @payment    = payment_class.create!(amount: 1379, currency: 'EUR', payment_class.third_attribute => max, mode: diesel, responsible: User.first, to_bank_at: Time.zone.now - 5.days)
  end
end
