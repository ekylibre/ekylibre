class ItkImportJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  # Import ITK for all activities in a campaign
  def perform(activity_ids, current_campaign, user)
    begin
      result = 0
      itk_service = ::TechnicalItineraries::Itk::ImportItkFromLexiconService.new(activity_ids: activity_ids, campaign: current_campaign)
      itk_service.perform
      result += itk_service.log_result[:count_tw_created].to_d
    rescue => error
      Rails.logger.error error
      Rails.logger.error error.backtrace.join("\n")
      ExceptionNotifier.notify_exception(error, data: { message: error })
    end
    notification = user.notifications.build(notification_params(result))
    notification.save
  end

  private

    def notification_params(result)
      {
        message: (result > 0 ? :x_activity_have_been_autoplanned_successfully : :activity_have_not_been_autoplanned),
        level: (result > 0 ? :success : :error),
        interpolations: { count: result.to_d }
      }
    end
end
