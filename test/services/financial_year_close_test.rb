require 'test_helper'

class FinancialYearCloseTest < ActiveSupport::TestCase
  setup do
    JournalEntry.update_all(state: :draft)
    JournalEntry.update_all(printed_on: Date.today)
    JournalEntryItem.update_all(bank_statement_letter: '')
    JournalEntryItem.update_all(state: :draft)
    OutgoingPayment.update_all(list_id: nil)
    TaxDeclaration.update_all(state: :draft)
    Version.delete_all
    Regularization.destroy_all
    TaxDeclaration.destroy_all
    OutgoingPaymentList.destroy_all
    OutgoingPayment.destroy_all
    Payslip.destroy_all
    PayslipNature.destroy_all
    FixedAssetDepreciation.destroy_all
    Inventory.destroy_all
    AccountBalance.destroy_all
    JournalEntry.destroy_all
    Deposit.destroy_all
    IncomingPayment.destroy_all
    IncomingPaymentMode.destroy_all
    OutgoingPaymentMode.destroy_all
    BankStatement.destroy_all
    Reception.update_all(state: :draft)
    Reception.destroy_all
    Shipment.update_all(state: :draft)
    Shipment.destroy_all
    ParcelItem.destroy_all
    Sale.update_all(state: :draft)
    Sale.destroy_all
    Purchase.update_all(state: :draft)
    Purchase.destroy_all
    InterventionParticipation.destroy_all
    EventParticipation.destroy_all
    Contract.destroy_all
    Product.update_all(tracking_id: nil)
    Tracking.destroy_all
    Delivery.destroy_all
    PurchaseAffair.destroy_all
    Subscription.destroy_all
    Gap.destroy_all
    EntityLink.destroy_all
    EntityAddress.destroy_all
    Entity.where.not(id: Entity.of_company.id).destroy_all
    ProductNatureCategoryTaxation.destroy_all
    Tax.destroy_all
    Analysis.destroy_all
    InterventionOutput.update_all(product_id: nil)
    InterventionProductParameter.destroy_all
    InterventionParameter.destroy_all
    Intervention.destroy_all
    Issue.destroy_all
    ActivityProduction.destroy_all
    Product.destroy_all
    ProductNatureVariant.destroy_all
    ProductNature.destroy_all
    ProductNatureCategory.destroy_all
    PurchaseItem.destroy_all
    SaleItem.destroy_all
    Loan.destroy_all
    Cash.destroy_all
    FinancialYear.destroy_all
    Account.destroy_all

    @dumpster_account = Account.create!(name: 'TestDumpster', number: '00000')
    @dumpster_journal = Journal.create!(name: 'Dumpster journal', code: 'DMPTST')
    @beginning = (Date.today - 1.month).beginning_of_month
    @end = (Date.today - 1.month).end_of_month
    @year = FinancialYear.create!(started_on: @beginning, stopped_on: @end)
    @next_year = FinancialYear.ensure_exists_at! @end + 1.day
    @profits = Account.create!(name: 'FinancialYear result profit', number: '120')
    @losses = Account.create!(name: 'FinancialYear result loss', number: '129')
    @open  = Account.create!(number: '89', name: 'Opening account')
    @close = Account.create!(number: '891', name: 'Closing account')
  end

  test 'products & expenses balance' do
    result = Journal.create!(name: 'Results TEST', code: 'RSTST', nature: :result)
    test_accounts = {
      6012 => Account.create!(name: 'Test6x', number: '6012'),
      6063 => Account.create!(name: 'Test6x2', number: '6063')
    }

    generate_entry(test_accounts[6012], 5000)
    generate_entry(test_accounts[6063], -3000)
    validate_fog

    close = FinancialYearClose.new(@year, @year.stopped_on, result_journal: result)
    close.execute

    assert_equal 3, JournalEntry.count
    assert_equal 0, test_accounts[6012].journal_entry_items.sum('debit - credit')
    assert_equal 0, test_accounts[6063].journal_entry_items.sum('debit - credit')
    assert_equal 2000, @losses.journal_entry_items.sum('debit - credit')
  end

  test 'Carry-forward letterable items' do
    result = Journal.create!(name: 'Results TEST', code: 'RSTST', nature: :result)
    closing = Journal.create!(name: 'Close TEST', code: 'CLOSTST', nature: :closure)
    forward = Journal.create!(name: 'Forward TEST', code: 'FWDTST', nature: :forward)
    test_accounts = [
      nil,
      Account.create!(name: 'Test1x', number: '1222'),
      Account.create!(name: 'Test2x', number: '2111'),
      Account.create!(name: 'Test3x', number: '3444'),
      Account.create!(name: 'Test4x', number: '4333')
    ]

    generate_entry(test_accounts[1], 2000)
    generate_entry(test_accounts[1], 300)
    generate_entry(test_accounts[2], -500)
    generate_entry(test_accounts[2], -300)
    generate_entry(test_accounts[3],  200)
    generate_entry(test_accounts[3],  200)
    generate_entry(test_accounts[4], -465)
    generate_entry(test_accounts[4], -300)
    validate_fog

    close = FinancialYearClose.new(@year, @year.stopped_on,
                                   result_journal: result,
                                   closure_journal: closing,
                                   forward_journal: forward)
    close.execute

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
    result = Journal.create!(name: 'Results TEST', code: 'RSTST', nature: :result)
    closing = Journal.create!(name: 'Close TEST', code: 'CLOSTST', nature: :closure)
    forward = Journal.create!(name: 'Forward TEST', code: 'FWDTST', nature: :forward)
    test_accounts = [
      nil,
      Account.create!(name: 'Test1x', number: '1222'),
      Account.create!(name: 'Test2x', number: '2111'),
      Account.create!(name: 'Test3x', number: '3444'),
      Account.create!(name: 'Test4x', number: '4333')
    ]

    letter = test_accounts[4].new_letter
    this_years = {
      300 => generate_entry(test_accounts[4],  500, letter: letter),
      500 => generate_entry(test_accounts[4],  300, letter: letter)
    }
    next_years = generate_entry(test_accounts[4], -800, letter: letter, printed_on: @end + 2.days)
    validate_fog

    close = FinancialYearClose.new(@year, @year.stopped_on,
                                   result_journal: result,
                                   closure_journal: closing,
                                   forward_journal: forward)
    close.execute

    assert_equal 4, @year.journal_entries.count
    assert_equal 3, @next_year.journal_entries.count

    assert_equal 2, @close.journal_entry_items.count
    assert_equal 2, @open.journal_entry_items.count

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

  private

  def generate_entry(account, debit, letter: nil, printed_on: @beginning + 2.days)
    return if debit.zero?
    side = debit > 0 ? :debit : :credit
    other_side = debit < 0 ? :debit : :credit
    amount = debit.abs
    JournalEntry.create!(journal: @dumpster_journal, printed_on:  printed_on, items_attributes: [
                           {
                             name: side.to_s.capitalize,
                             account: account,
                             letter: letter,
                             :"real_#{side}" => amount
                           },
                           {
                             name: other_side.to_s.capitalize,
                             account: @dumpster_account,
                             :"real_#{other_side}" => amount
                           }
                         ])
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
