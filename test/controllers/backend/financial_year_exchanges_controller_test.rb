require 'test_helper'
module Backend
  class FinancialYearExchangesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    include ActiveJob::TestHelper

    test_restfully_all_actions except: %i[journal_entries_export journal_entries_import notify_accountant notify_accountant_modal close create]
    # TODO: Write tests for #journal_entries_export, #journal_entries_import, #notify_accountant, #close

    journal_entries_export_formats = %i[csv fec_txt fec_xml]
    journal_entries_export_formats.each do |format|
      test "export journal entries with format #{format}" do
        run_journal_entries_export_with_format(format)
      end

      test "notify accountant with format #{format}" do
        run_notify_accountant_with_format(format)
      end
    end

    test 'notify accountant with no email should return error message' do
      exchange_setup_with_accountant(with_email: false)
      perform_enqueued_jobs do
        get :notify_accountant, params: { id: @exchange.id, format: :csv }
      end

      assert_equal [I18n.t('notifications.messages.accountant_without_email')], flash["notifications"]["error"]
    end

    test 'journal entries export with wrong format should raise error' do
      exchange_setup
      perform_enqueued_jobs do
        get :journal_entries_export, params: { id: @exchange.id, format: 'toto' }
      end

      assert Notification.find_by(message: :error_during_file_generation.tl)
    end

    test 'selecting journals should set financial year exchange id then close should remove it' do
      empty_db
      fy = create(:financial_year, year: 2021)
      journal1 = create(:journal)
      journal2 = create(:journal)
      journal3 = create(:journal)
      journal4 = create(:journal)
      post :create, params: { financial_year_exchange: { financial_year_id: fy.id, started_on: '15/01/2021', stopped_on: '20/01/2021', exported_journal_ids: [journal1.id, journal2.id, journal3.id] } }
      exchange = FinancialYearExchange.last
      assert_equal exchange.id, journal1.reload.financial_year_exchange_id
      assert_equal exchange.id, journal2.reload.financial_year_exchange_id
      assert_equal exchange.id, journal3.reload.financial_year_exchange_id
      assert_equal nil, journal4.reload.financial_year_exchange_id
      get :close, params: { id: exchange.id }
      assert_equal nil, journal1.reload.financial_year_exchange_id
      assert_equal nil, journal2.reload.financial_year_exchange_id
      assert_equal nil, journal3.reload.financial_year_exchange_id
      assert_equal nil, journal4.reload.financial_year_exchange_id
    end

    private def run_journal_entries_export_with_format(format)
      exchange_setup
      perform_enqueued_jobs do
        get :journal_entries_export, params: { id: @exchange.id, format: format }
      end

      assert_equal [I18n.t('notifications.messages.document_in_preparation')], flash["notifications"]["success"]

      notification = Notification.find_by(message: :journal_entries_export_file_generated.tl)
      assert notification

      document = notification.target
      assert document
      assert document.file
      assert_equal "application/zip", document.file_content_type
    end

    private def run_notify_accountant_with_format(format)
      exchange_setup_with_accountant
      perform_enqueued_jobs do
        get :notify_accountant, params: { id: @exchange.id, format: format }
      end

      assert_equal [I18n.t('notifications.messages.document_in_preparation')], flash["notifications"]["success"]

      assert Notification.find_by(message: :accountant_notified.tl)
    end

    private def empty_db
      FinancialYear.delete_all
      FinancialYearExchange.delete_all
      Notification.delete_all
      Inventory.delete_all
      Payslip.delete_all
      PayslipNature.delete_all
      Journal.delete_all
    end

    private def exchange_setup
      empty_db
      create(:journal)
      fy = create(:financial_year, year: 2021)
      @exchange = create(:financial_year_exchange, financial_year: fy)
    end

    private def exchange_setup_with_accountant(with_email: true)
      empty_db
      create(:journal)
      accountant = if with_email
                     create(:entity, :with_email)
                   else
                     create(:entity)
                   end
      fy = create(:financial_year, year: 2021, accountant: accountant)
      @exchange = create(:financial_year_exchange, financial_year: fy)
    end

    test 'close should remove exchange id value from associated journal entries' do
      empty_journal_entries
      fy = create(:financial_year, year: 2021)
      printed_on_dates = %w[2021-01-09 2021-01-11 2021-01-14 2021-01-16 2021-01-25]
      printed_on_dates.each do |date|
        create(:journal_entry, :with_items, printed_on: date)
      end
      exchange = create(:financial_year_exchange, :opened, financial_year: fy, started_on: '2021-01-10', stopped_on: '2021-01-20')
      assert_equal 3, exchange.journal_entries.count

      get :close, params: { id: exchange.id }
      assert_equal 0, exchange.journal_entries.count
    end

    private

      def empty_journal_entries
        FinancialYear.delete_all
        OutgoingPayment.delete_all
        Regularization.delete_all
        Payslip.delete_all
        JournalEntryItem.delete_all
        JournalEntry.delete_all
      end
  end
end
