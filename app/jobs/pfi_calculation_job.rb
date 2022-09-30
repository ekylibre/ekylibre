class PfiCalculationJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  # Compute and store(create or update) pfi for each intervention in a campaign
  def perform(campaign, interventions, perform_as)
    if Interventions::Phytosanitary::PfiClientApi.new(campaign: campaign).down?
      perform_as.notifications.create!(pfi_api_down_notification_generation)
      return
    end

    begin
      result = 0
      interventions.each do |intervention|
        pfi_computation = Interventions::Phytosanitary::PfiComputation.new(campaign: campaign, intervention: intervention)
        pfi_computation.create_or_update_pfi
        result += 1
      end
    rescue => error
      Rails.logger.error error
      Rails.logger.error error.backtrace.join("\n")
      ExceptionNotifier.notify_exception(error, data: { message: error })
    end
    notification = perform_as.notifications.build(notification_params(result))
    notification.save
  end

  private

    def notification_params(result)
      {
        message: (result > 0 ? :pfi_have_been_computed : :pfi_have_not_been_computed),
        level: (result > 0 ? :success : :error),
        target_type: 'Intervention',
        interpolations: {}
      }
    end

    def pfi_api_down_notification_generation
      {
        message: :pfi_api_down.tl,
        level: :error,
        interpolations: {}
      }
    end
end
