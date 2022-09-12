# frozen_string_literal: true

module Interventions
  class LinkRidesToPlannedJob < ApplicationJob
    include Rails.application.routes.url_helpers
    queue_as :default

    before_enqueue do |job|
      change_rides_conversion_state(job.arguments.second, true)
    end

    after_perform do |job|
      change_rides_conversion_state(job.arguments.second, false)
    end

    protected

      def perform(intervention, rides, perform_as:, **options)
        begin
          ActiveRecord::Base.transaction do
            intervention = ::Interventions::ChangeState.call(intervention: intervention, new_state: :done)

            target_class = Product.where(id: intervention.targets.pluck(:product_id)).pluck(:type).first&.constantize
            intervention.targets.destroy_all
            intervention.working_periods.destroy_all
            options_from_rides = ::Interventions::Geolocation::AttributesBuilderFromRides.call(
              ride_ids: rides.map(&:id),
              procedure_name: intervention.procedure_name,
              target_class: target_class
            )
            intervention.update!(options_from_rides)

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

      def change_rides_conversion_state(rides, is_converting)
        rides.each do |ride|
          ride.reload.update(converting_to_intervention: is_converting)
        end
      end

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
