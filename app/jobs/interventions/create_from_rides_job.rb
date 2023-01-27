# frozen_string_literal: true

module Interventions
  class CreateFromRidesJob < ApplicationJob
    include Rails.application.routes.url_helpers
    queue_as :default

    protected

      def perform(intervention_options, rides, perform_as:, **options)
        begin
          ActiveRecord::Base.transaction do
            intervention_options[:creator_id] = perform_as.id
            options_from_rides = ::Interventions::Geolocation::AttributesBuilderFromRides.call(
              ride_ids: rides.map(&:id),
              procedure_name: intervention_options[:procedure_name]
            )

            intervention = Intervention.new(intervention_options.merge!(options_from_rides))
            intervention.save!

            perform_as.notifications.create!(success_notification_params(intervention.id))
          end
        rescue StandardError => error
          Rails.logger.error error
          Rails.logger.error error.backtrace.join("\n")
          ExceptionNotifier.notify_exception(error, data: { message: error })
          ElasticAPM.report(error)
          perform_as.notifications.create!(error_notification_params(error.message))
        end
      end

    private
      def error_notification_params(error)
        {
          message: 'error_during_intervention_creation_from_rides',
          level: :error,
          interpolations: {
            error_message: error
          }
        }
      end

      def success_notification_params(id)
        {
          message: 'intervention_created_from_rides',
          level: :success,
          target_type: 'Intervention',
          target_url: backend_intervention_path(id),
          interpolations: {}
        }
      end
  end
end
