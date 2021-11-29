class GlobalCostExportJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(activity_id:, campaign_ids:, plant_id: nil, land_parcel_id: nil, user:)
    begin
      # build & check params
      params = {}

      @activity = Activity.find_by(id: activity_id)
      params[:activity_id] = @activity.id if @activity

      @campaigns = Campaign.where(id: campaign_ids)
      params[:campaign_ids] = @campaigns.pluck(:id) if @campaigns.any?

      @plant = Plant.find_by(id: plant_id) if plant_id
      params[:plant_id] = @plant.id if @plant

      @land_parcel = LandParcel.find_by(id: land_parcel_id) if land_parcel_id
      params[:land_parcel_id] = @land_parcel.id if @land_parcel

      # call and generate the dataset
      export = ::Interventions::Exports::GlobalCostsXslxExport.new
      data = export.generate(params)
      # compute export name and set name
      document_name = "#{:document_global_costs.tl} - #{compute_export_name}"
      filename = "#{:export_global_costs.tl}_#{compute_export_name}.xlsx"
      # create document
      document = Document.create!(key: "#{Time.now.to_i}-#{filename}", name: document_name, file: data, file_file_name: filename)
      notification = user.notifications.build(success_full_interventions_registry_notification(document_name, document.id))
    rescue StandardError => e
      Rails.logger.error e
      Rails.logger.error e.backtrace.join("\n")
      ExceptionNotifier.notify_exception(e, data: { message: e })
      notification = user.notifications.build(error_full_interventions_registry_notification(@activity.id, e.message))
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
      harvest_years = @campaigns.pluck(:harvest_year)
      computed_name = "#{@activity.name}_#{harvest_years.join('-')}"
      if @plant
        computed_name << "_#{@plant.name}"
      elsif @land_parcel
        computed_name << "_#{@land_parcel.name}"
      end
      return computed_name
    end
end
