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
      else
        notification = user.notifications.build(error_generation_notification_params(filename, 'pfi_report', $ERROR_INFO.backtrace.join("\n")))
      end
    rescue => error
      Rails.logger.error $ERROR_INFO
      Rails.logger.error $ERROR_INFO.backtrace.join("\n")
      ExceptionNotifier.notify_exception($ERROR_INFO, data: { message: error })
      notification = user.notifications.build(error_generation_notification_params(filename, 'pfi_report', $ERROR_INFO.backtrace.join("\n")))
    end
    notification.save
  end
end
