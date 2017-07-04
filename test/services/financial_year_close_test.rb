require 'test_helper'

class FinancialYearCloseTest < ActiveSupport::TestCase
  setup do
    JournalEntry.update_all(state: :draft)
    JournalEntry.update_all(printed_on: Date.today)
    JournalEntryItem.update_all(bank_statement_letter: "")
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
    Parcel.update_all(state: :draft)
    Parcel.destroy_all
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
    @profits = Account.create!(name: 'FinancialYear result profit', number: '120')
    @losses = Account.create!(name: 'FinancialYear result loss', number: '129')
  end

  test 'products & expenses balance' do
    result = Journal.create!(name: 'Results TEST', code: 'RSTST', nature: :result)
    test_accounts = {
      6012 => Account.create!(name: 'Test6x', number: '6012'),
      6063 => Account.create!(name: 'Test6x2', number: '6063')
    }

    generate_entry(test_accounts[6012],  5000)
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
    generate_entry(test_accounts[1],  300)
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

  private

  def generate_entry(account, amount)
    return if amount.zero?
    side = amount > 0 ? :debit : :credit
    other_side = amount < 0 ? :debit : :credit
    JournalEntry.create!(journal: @dumpster_journal, printed_on:  @beginning + 2.days, items_attributes: [
      {
        name: side.to_s.capitalize,
        account: account,
        :"real_#{side}" => amount.abs
      },
      {
        name: other_side.to_s.capitalize,
        account: @dumpster_account,
        :"real_#{other_side}" => amount.abs
      }
    ])
  end

  def validate_fog
    JournalEntry.find_each { |je| je.update(state: :confirmed) }
  end
end
