class ToolCostExportJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(activity_id: nil, campaign_ids:, equipment_ids:, user:)
    begin
      # build & check params
      params = {}

      @activity = Activity.find_by(id: activity_id) if activity_id.present?
      params[:activity_id] = @activity.id if @activity

      @campaigns = Campaign.where(id: campaign_ids)
      params[:campaign_ids] = @campaigns.pluck(:id) if @campaigns.any?

      @equipments = Equipment.where(id: equipment_ids)
      params[:equipment_ids] = @equipments.pluck(:id) if @equipments.any?

      # call and generate the dataset
      export = ::Interventions::Exports::ToolCostsXslxExport.new
      data = export.generate(params)
      # compute export name and set name
      document_name = "#{:document_tool_costs.tl} - #{compute_export_name}"
      filename = "#{:export_tool_costs.tl}_#{compute_export_name}.xlsx"
      # create document
      document = Document.create!(key: "#{Time.now.to_i}-#{filename}", name: document_name, file: data, file_file_name: filename)
      notification = user.notifications.build(success_full_interventions_registry_notification(document_name, document.id))
    rescue StandardError => error
      Rails.logger.error error
      Rails.logger.error error.backtrace.join("\n")
      ExceptionNotifier.notify_exception(error, data: { message: error })
      notification = user.notifications.build(error_full_interventions_registry_notification(@equipments.first.id, error.message))
    end
    notification.save
  end

  private

    # Begin of notifs builder
    def error_full_interventions_registry_notification(id, error)
      {
        message: 'error_during_file_generation',
        level: :error,
        target_type: 'Document',
        target_url: backend_activity_path(id),
        interpolations: {
          error_message: error
        }
      }
    end

    def success_full_interventions_registry_notification(document_name, document_id)
      {
        message: "#{document_name} #{:ready.tl}",
        level: :success,
        target_type: 'Document',
        target_id: document_id,
        target_url: backend_document_path(document_id),
        interpolations: {}
      }
    end
    # End of notifs builder

    def compute_export_name
      equipment_names = @equipments.pluck(:name) if @equipments.any?
      computed_name = equipment_names.join('-')
      if @activity
        computed_name << "_#{@activity.name}"
      end
      if @campaigns.any?
        campaign_names = @campaigns.pluck(:harvest_year)
        computed_name << "_#{campaign_names.join('-')}"
      end
      return computed_name
    end
end
