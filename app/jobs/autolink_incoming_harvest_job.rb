class AutolinkIncomingHarvestJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(ih_ids:, user:)
    begin
      service = Interventions::AutolinkInterventionWithIncomingHarvestService.new(ih_ids)
      result = service.perform
      notification = user.notifications.build(success_autolink_incoming_harvest_notification(result))
    rescue StandardError => e
      Rails.logger.error e
      Rails.logger.error e.backtrace.join("\n")
      ExceptionNotifier.notify_exception(e, data: { message: e })
      notification = user.notifications.build(error_autolink_incoming_harvest_notification(e.message))
    end
    notification.save
  end

  private

    # Begin of notifs builder
    def error_autolink_incoming_harvest_notification(error)
      {
        message: 'error_linked_harvest_intervention_with_incoming_harvest',
        level: :error,
        interpolations: {
          error: error
        }
      }
    end

    def success_autolink_incoming_harvest_notification(result)
      {
        message: "successful_linked_harvest_intervention_with_incoming_harvest",
        level: :success,
        interpolations: {
          it_count: result[:intervention_count],
          ihc_count: result[:incoming_harvest_crop_count]
        }
      }
    end

end
