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
    test_account = Account.create!(name: 'Test601x', number: '6012')
    JournalEntry.create!(journal: @dumpster_journal, printed_on:  @beginning + 2.days, items_attributes: [
      {
        name: 'Debit',
        account: test_account,
        real_debit: 5000
      },
      {
        name: 'Credit',
        account: @dumpster_account,
        real_credit: 5000
      }
    ])
    JournalEntry.find_each { |je| je.update(state: :confirmed) }
    close = FinancialYearClose.new(@year, @year.stopped_on, result_journal: result)
    close.execute

    assert_equal 2, JournalEntry.count
    assert_equal 0, test_account.journal_entry_items.sum('debit - credit')
    assert_equal 5000, @losses.journal_entry_items.sum('debit - credit')
  end
end
