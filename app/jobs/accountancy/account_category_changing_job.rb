module Accountancy
  class AccountCategoryChangingJob < ActiveJob::Base
    queue_as :default
    include Rails.application.routes.url_helpers

    # modes Array of Symbol, could be :sale, :purchase
    # financial_year FinancialYear, default is current
    # category ProductNatureCategory
    # variant_id Integer of ProductNatureVariant
    def perform(category:, financial_year_ids:, modes:, variant_id: nil, perform_as:)
      account_service_changing = Accountancy::AccountCategoryChanging.new(category: category, financial_year_ids: financial_year_ids, modes: modes, variant_id: variant_id)
      account_service_changing.perform
      infos = account_service_changing.result_infos
      infos.each do |info|
        perform_as.notifications.create!(success_notification_params(info))
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
      def success_notification_params(info)
        {
          message: :account_changing_updated.tl,
          level: :success,
          target_type: '',
          target_url: '',
          interpolations: { count: info[:count], mode: info[:mode].to_sym.tl, number: info[:account_number] }
        }
      end
  end
end
