require 'test_helper'
module Backend
  class FinancialYearExchangesControllerTest < Ekylibre::Testing::ApplicationControllerTestCase::WithFixtures
    include ActiveJob::TestHelper

    test_restfully_all_actions except: %i[journal_entries_export journal_entries_import notify_accountant notify_accountant_modal close toto]
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
      assert_equal document.file_content_type, "application/zip"
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
    end

    private def exchange_setup
      empty_db
      fy = create(:financial_year, year: 2021)
      @exchange = create(:financial_year_exchange, financial_year: fy)
    end

    private def exchange_setup_with_accountant(with_email: true)
      empty_db
      accountant = if with_email
                     create(:entity, :with_email)
                   else
                     create(:entity)
                   end
      fy = create(:financial_year, year: 2021, accountant: accountant)
      @exchange = create(:financial_year_exchange, financial_year: fy)
    end
  end
end
