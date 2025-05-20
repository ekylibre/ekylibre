class AgromonitoringJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(parcel_id:, user_id: nil)
    user = User.find(user_id) if user_id
    parcel = CultivableZone.find(parcel_id)
    identifier = Identifier.find_by(nature: :agromonitoring_api_key)
    begin
      # set service api with polygon
      service = AgroMonitoringClient.from_identifier(identifier, parcel, user)
      cz_analysis_service = CultivableZoneAnalysis.new(parcel)
      last_ndvi_analysed_at = cz_analysis_service.find_last_analysis(:ndvi)
      service.set_polygon
      # get ndvi history from agromonitoring api according to last_ndvi_analysed_at in DB
      if last_ndvi_analysed_at.present?
        ndvi_items = service.grab_ndvi_history(last_ndvi_analysed_at)
      else
        ndvi_items = service.grab_ndvi_history
      end
      # store ndvi history in DB
      cz_analysis_service.create_agromonitoring_ndvi_analysis(ndvi_items)
      # get current soil from agromonitoring api
      soil_item = service.grab_current_soil
      # store soil in DB
      cz_analysis_service.create_agromonitoring_soil_analysis(soil_item)
      notification = user.notifications.build(success_on_agromonitoring_notification) if user.present?
    rescue StandardError => e
      ExceptionNotifier.notify_exception(e, data: { message: e })
      notification = user.notifications.build(error_on_agromonitoring_notification(e.message)) if user.present?
    end
    notification.save if notification.present?
  end

  private

    # Begin of notifs builder
    def error_on_agromonitoring_notification(error)
      {
        message: 'error_on_agromonitoring_notification',
        level: :error,
        interpolations: {
          error: error
        }
      }
    end

    def success_on_agromonitoring_notification
      {
        message: "success_on_agromonitoring_notification",
        level: :success,
        interpolations: {}
      }
    end

end
