require 'test_helper'

module Fec
  module Check
    class JournalEntryTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures

      setup do
        [Inventory, Payslip, PayslipNature, Journal, Regularization, OutgoingPayment, JournalEntry, JournalEntryItem, FinancialYear].map(&:delete_all)
      end

      test 'entry items should have same name' do
        create(:financial_year, started_on: '01-01-2016', stopped_on: '31-12-2016')
        account = create(:account)
        item_1_attrs = attributes_for_list(:journal_entry_item, 2, name: "toto", account_id: account.id)
        entry1 = build(:journal_entry)
        entry1.items.build(item_1_attrs)
        entry1.save!
        assert entry1.compliance_errors.exclude?('entry_name_not_uniq')

        item_2_attrs = attributes_for(:journal_entry_item, name: "tata", account_id: account.id)
        entry2 = build(:journal_entry)
        entry2.items.build(item_1_attrs)
        entry2.items.build(item_2_attrs)
        entry2.save!
        assert entry2.compliance_errors.include?('entry_name_not_uniq')
      end

      test 'entry should not be created on holiday day' do
        create(:financial_year, started_on: '01-01-2020', stopped_on: '31-12-2020')
        Timecop.freeze('2020-01-01') do |new_years_day|
          entry = create(:journal_entry_with_items, printed_on: new_years_day, created_at: new_years_day)
          assert entry.compliance_errors.include?('created_on_free_day')
        end
      end

      test 'entry should not be created on weekend days' do
        create(:financial_year, started_on: '01-01-2020', stopped_on: '31-12-2020')
        days_of_week = Date.parse('20-04-2020')..Date.parse('26-04-2020')
        free_days = %w[Saturday Sunday]
        days_of_week.each do |day|
          entry = create(:journal_entry_with_items, printed_on: day, created_at: day)
          if free_days.include?(day.strftime("%A"))
            assert entry.compliance_errors.include?('created_on_free_day')
          else
            assert entry.compliance_errors.exclude?('created_on_free_day')
          end
        end
      end

      test 'entry should not have negative or empty credit or credit' do
        create(:financial_year, started_on: '01-01-2016', stopped_on: '31-12-2016')
        entry = create(:journal_entry_with_items, with_credit: 50, with_debit: 50)
        assert entry.compliance_errors.exclude?('negative_or_empty_debit_or_credit')

        entry.update_attribute(:real_credit, -42)
        entry.update_attribute(:real_debit, 0)
        assert entry.compliance_errors.include?('negative_or_empty_debit_or_credit')
        entry.update_attribute(:real_credit, 0)
        entry.update_attribute(:real_debit, -42)
        assert entry.compliance_errors.include?('negative_or_empty_debit_or_credit')
      end

      test 'entry items should have unique account name' do
        create(:financial_year, started_on: '01-01-2016', stopped_on: '31-12-2016')
        account_with_uniq_name = create(:account, name: 'toto')
        item_attrs = attributes_for(:journal_entry_item, account_id: account_with_uniq_name.id)
        entry = build(:journal_entry)
        entry.items.build(item_attrs)
        entry.save!
        assert entry.compliance_errors.exclude?('entry_item_account_name_not_uniq')
        accounts_with_same_name = create_list(:account, 2, name: 'tata')
        item_attrs = attributes_for(:journal_entry_item, account_id: accounts_with_same_name.first.id)
        entry = build(:journal_entry)
        entry.items.build(item_attrs)
        entry.save
        assert entry.compliance_errors.include?('entry_item_account_name_not_uniq')
      end

      test 'entry items name should not include certain keywords' do
        create(:financial_year, started_on: '01-01-2016', stopped_on: '31-12-2016')
        I18n.locale = :fra
        account = create(:account)
        %w[Erreur Regul Réaffectation Reclassement Fisc].each do |risky_word|
          item_attrs = attributes_for(:journal_entry_item, name: "#{risky_word} de montant", account_id: account.id)
          entry = build(:journal_entry)
          entry.items.build(item_attrs)
          entry.save!
          assert entry.compliance_errors.include?('risky_keyword')
        end
      end

      test 'entry items name should not include special caracters' do
        create(:financial_year, started_on: '01-01-2016', stopped_on: '31-12-2016')
        account = create(:account)
        item_attrs = attributes_for(:journal_entry_item, name: "toto;", account_id: account.id)
        entry = build(:journal_entry)
        entry.items.build(item_attrs)
        entry.save!
        assert entry.compliance_errors.include?('special_caracter')
      end

      test 'entry should not be printed_on be more than 60 days ago' do
        create(:financial_year, started_on: '01-01-2019', stopped_on: '31-12-2019')
        create(:financial_year, started_on: '01-01-2020', stopped_on: '31-12-2020')
        # Validated_at not nil : compare with validated_at
        entry = create(:journal_entry_with_items, printed_on: '01/02/2020', validated_at: '01/03/2020')
        assert entry.compliance_errors.exclude?('printed_on_more_than_60_days_ago')
        entry.update(printed_on: '15/12/2019')
        assert entry.compliance_errors.include?('printed_on_more_than_60_days_ago')
        # Validated_at nil : compare with current day
        Timecop.freeze('01/03/2020') do
          entry = create(:journal_entry_with_items, printed_on: '01/02/2020')
          assert entry.compliance_errors.exclude?('printed_on_more_than_60_days_ago')
          entry.update(printed_on: '15/12/2019')
          assert entry.compliance_errors.include?('printed_on_more_than_60_days_ago')
        end
      end
    end
  end
end
