module Accountancy
  class AccountingSystemChangingJob < ActiveJob::Base
    queue_as :default
    include Rails.application.routes.url_helpers

    # modes Array of Symbol, could be :sale, :purchase
    # financial_year FinancialYear, default is current
    # category ProductNatureCategory
    # variant_id Integer of ProductNatureVariant
    def perform(financial_year_id:, old_accounting_system:, new_accounting_system:, perform_as:)
      accounting_service_changing = Accountancy::AccountingSystemChanging.new(financial_year_id: financial_year_id, old_accounting_system: old_accounting_system, new_accounting_system: new_accounting_system)
      accounting_service_changing.perform
      infos = accounting_service_changing.result_infos
      if infos[:error].present?
        perform_as.notifications.create!(error_notification_params(infos[:error]))
      else
        perform_as.notifications.create!(success_notification_params(infos))
      end
    rescue StandardError => error
      Rails.logger.error error
      Rails.logger.error error.backtrace.join("\n")
      ExceptionNotifier.notify_exception(error, data: { message: error })
      perform_as.notifications.create!(error_notification_params(error.message))
    end

    private

      def error_notification_params(error)
        {
          message: 'error',
          level: :error,
          target_type: '',
          target_url: '',
          interpolations: {
            error_message: error
          }
        }
      end

      # info is a Hash example : { mode: 'purchase', count: 5}
      def success_notification_params(infos)
        {
          message: :accounting_system_changed.tl,
          level: :success,
          target_type: '',
          target_url: '',
          interpolations: { count_accounts: infos[:count_accounts], count_entries: infos[:count_entries], accounting_system: infos[:accounting_system] }
        }
      end
  end
end
