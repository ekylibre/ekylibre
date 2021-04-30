class PfiReportJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  # Compute and store(create or update) pfi for each intervention in a campaign
  def perform(campaign, activity_ids, user)
    begin
      activities = Activity.where(id: activity_ids)
      pfi_computation = Interventions::Phytosanitary::PfiComputation.new(campaign: campaign, activities: activities)
      response = pfi_computation.create_pfi_report
      filename = "Bilan_IFT_#{campaign.name}.pdf"
      if response[:status] == true
        file_path = Ekylibre::Tenant.private_directory.join('tmp', filename.to_s)
        FileUtils.mkdir_p(file_path.dirname)
        File.open(file_path, "wb:ASCII-8BIT") do |file|
          file.write(response[:body])
        end
        # TODO
        # change nature of the document - waiting for Onoma new release
        # nature: 'pfi_land_parcel_register'
        document = Document.create!(nature: "phytosanitary_certification", key: "#{Time.now.to_i}-#{filename}", name: filename, file: File.open(file_path))
        notification = user.notifications.build(valid_generation_notification_params(file_path, filename, document.id))
      elsif response[:status] == false
        ExceptionNotifier.notify_exception(response[:body], data: { message: response[:body] })
        notification = user.notifications.build(error_generation_notification_params(filename, 'pfi_report', response[:body]))
      elsif response[:status] == :e_activities_production_nature
        ExceptionNotifier.notify_exception(response[:body], data: { message: response[:body] })
        notification = user.notifications.build(error_production_nature_notification_params(response[:body]))
      end
    rescue => error
      Rails.logger.error error
      Rails.logger.error error.backtrace.join("\n")
      ExceptionNotifier.notify_exception(error, data: { message: error })
      ElasticAPM.report(error)
      notification = user.notifications.build(error_generation_notification_params(filename, 'pfi_report', error.message))
    end
    notification.save
  end

  private

    def error_generation_notification_params(filename, id, error)
      {
        message: 'error_during_pfi_report_generation',
        level: :error,
        interpolations: {
          error_message: error
        }
      }
    end

    def error_production_nature_notification_params(activities_name)
      {
        message: 'missing_production_nature_on_activity',
        level: :error,
        interpolations: {
          activities_name: activities_name
        }
      }
    end

    def valid_generation_notification_params(_path, _filename, document_id)
      {
        message: 'file_generated',
        level: :success,
        target_type: 'Document',
        target_url: backend_document_path(document_id),
        interpolations: {}
      }
    end

end
