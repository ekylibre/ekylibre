class PfiCalculationJob < ApplicationJob
  queue_as :default

  # Compute and store(create or update) pfi for each intervention in a campaign
  def perform(campaign, intervention_ids, user)
    begin
      result = 0
      Intervention.where(id: intervention_ids).each do |intervention|
        pfi_computation = Interventions::Phytosanitary::PfiComputation.new(campaign: campaign, intervention: intervention)
        pfi_computation.create_or_update_pfi
        result += 1
      end
    rescue => error
      Rails.logger.error $ERROR_INFO
      Rails.logger.error $ERROR_INFO.backtrace.join("\n")
      ExceptionNotifier.notify_exception($ERROR_INFO, data: { message: error })
    end
    notification = user.notifications.build(notification_params(result))
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
end
