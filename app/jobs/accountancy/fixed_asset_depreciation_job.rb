module Accountancy
  class FixedAssetDepreciationJob < ActiveJob::Base
    queue_as :default
    include Rails.application.routes.url_helpers

    protected

      def perform(fixed_asset_ids, *args, up_to:, perform_as:, **options)
        count = FixedAssetDepreciator.new.depreciate(FixedAsset.find(fixed_asset_ids), up_to: Date.parse(up_to))
        perform_as.notifications.create!(success_notification_params(count))
      rescue StandardError => error
        Rails.logger.error error
        Rails.logger.error error.backtrace.join("\n")
        ExceptionNotifier.notify_exception(error, data: { message: error })
        perform_as.notifications.create!(error_notification_params(error.message))
      end

    private

      def error_notification_params(error)
        {
          message: 'fixed_asset_depreciations_have_not_been_bookkept',
          level: :error,
          target_type: '',
          target_url: '',
          interpolations: {
            error_message: error
          }
        }
      end

      def success_notification_params(count)
        {
          message: 'x_fixed_asset_depreciations_have_been_bookkept_successfully',
          level: :success,
          target_type: '',
          target_url: '',
          interpolations: { count: count }
        }
      end
  end
end
