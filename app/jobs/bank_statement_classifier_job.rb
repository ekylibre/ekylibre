class BankStatementClassifierJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(bs_ids:, user:)
    begin
      BankStatementClassifierService.classify_from_data(bank_statement_ids: bs_ids)
      service = BankStatementClassifierService.call(bank_statement_ids: bs_ids)
      notification = user.notifications.build(success_on_bank_classification_notification(service))
    rescue StandardError => e
      ExceptionNotifier.notify_exception(e, data: { message: e })
      notification = user.notifications.build(error_on_bank_classification_notification(e.message))
    end
    notification.save
  end

  private

    # Begin of notifs builder
    def error_on_bank_classification_notification(error)
      {
        message: 'error_on_bank_classification',
        level: :error,
        interpolations: {
          error: error
        }
      }
    end

    def success_on_bank_classification_notification(result)
      {
        message: "successful_on_bank_classification",
        level: :success,
        interpolations: {
          it_count: result[:items_classified]
        }
      }
    end

end
