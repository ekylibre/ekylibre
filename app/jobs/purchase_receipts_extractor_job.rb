class PurchaseReceiptsExtractorJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(financial_years:, user:)
    extractor = PurchaseInvoices::ReceiptsExtractor.build
    document = extractor.create_zip(financial_years)

    user.notifications.create!(success_notification_params(document.id))
  rescue StandardError => error
    Rails.logger.error error
    Rails.logger.error error.backtrace.join("\n")
    ExceptionNotifier.notify_exception(error, data: { message: error })
    user.notifications.create!(error_notification_params(error.message))
  end

  private

    def error_notification_params(error)
      {
        message: 'error_during_file_generation',
        level: :error,
        interpolations: {
          error_message: error
        }
      }
    end

    def success_notification_params(document_id)
      {
        message: 'file_generated',
        level: :success,
        target_type: 'Document',
        target_url: backend_document_path(document_id),
        interpolations: {}
      }
    end
end
