module Api
  module V1
    # Observations API permits to access observations
    class YieldObservationsController < Api::V1::BaseController
      def create
        attributes = permitted_params.to_h.with_indifferent_access

        base64_pictures = attributes.delete(:pictures) || []
        plants = attributes.delete(:plants) || []
        issues = attributes.delete(:issues) || []

        observation = YieldObservation.new(attributes)

        observation.creator = current_user

        observation.plants = Plant.where(id: plants.collect { |p| p[:id] })

        issues = Issue.where(id: issues.collect { |p| p[:id] })
        issues.each do |issue|
          observation.plants.each_with_index do |plant, i|
            if i == 0
              issue.update(target: plant)
              observation.issues << issue
            else
              dup_issue = issue.dup
              dup_issue.update(target: plant)
              observation.issues << dup_issue
            end
          end
        end

        observation.attachments = base64_pictures.each_with_index.collect do |pic, i|
          file = Paperclip.io_adapters.for(pic, hash_digest: Digest::MD5)
          ext = Rack::Mime::MIME_TYPES.invert[file.content_type]
          file.original_filename = "observation_#{i+1}_#{Time.zone.now.to_i}#{ext}"
          Attachment.new(document_attributes: { file: file })
        end

        if observation.save
          # Issues are supposed to have their 'state' field to be set at 'opened' by default on save but it doesn't, so we update them all here manually
          observation.issues.update_all(state: 'opened')
          render json: { id: observation.id }, status: :created
        else
          render json: observation.errors, status: :unprocessable_entity
        end
      end

      protected

        def permitted_params
          super.permit(:observed_at, :activity_id, :vegetative_stage_id, :geolocation, :description, pictures: [], plants: %i[id], issues: %i[id])
        end
    end
  end
end
