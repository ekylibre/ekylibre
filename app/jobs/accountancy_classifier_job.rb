class AccountancyClassifierJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(journal_entry_item_ids:, user:)
    begin
      service = AccountancyClassifierService.new(journal_entry_item_ids: journal_entry_item_ids)
      service.classify_from_data
      service.classify_from_ia
      notification = user.notifications.build(success_on_accountancy_classification_notification(service))
    rescue StandardError => e
      ExceptionNotifier.notify_exception(e, data: { message: e })
      notification = user.notifications.build(error_on_accountancy_classification_notification(e.message))
    end
    notification.save
  end

  private

    # Begin of notifs builder
    def error_on_accountancy_classification_notification(error)
      {
        message: 'error_on_accountancy_classification',
        level: :error,
        interpolations: {
          error: error
        }
      }
    end

    def success_on_accountancy_classification_notification(result)
      {
        message: "successful_on_accountancy_classification",
        level: :success,
        interpolations: {
          it_count: result[:items_classified]
        }
      }
    end

end
