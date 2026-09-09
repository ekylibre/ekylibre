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
          document = build_document_from_data_uri(pic, "observation_#{i + 1}_#{Time.zone.now.to_i}")
          Attachment.new(document: document)
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

        # Paperclip.io_adapters savait lire une data-URI base64 ; Active Storage
        # attend un io. On décode donc nous-mêmes.
        #
        # @param data_uri [String] "data:image/jpeg;base64,...."
        # @param basename [String] nom du fichier, sans extension
        # @return [Document]
        # @raise [ActionController::BadRequest] si la data-URI est malformée
        def build_document_from_data_uri(data_uri, basename)
          match = data_uri.to_s.match(%r{\Adata:(?<type>[-\w.+]+/[-\w.+]+);base64,(?<payload>.+)\z}m)
          raise ActionController::BadRequest.new('Malformed picture payload') if match.nil?

          content_type = match[:type]
          extension = Rack::Mime::MIME_TYPES.invert[content_type]
          filename = "#{basename}#{extension}"

          # Comme avant : aucune nature n'est fixée ici, Document s'en charge.
          document = Document.new(name: filename, key: "#{Time.now.to_i}-#{filename}")
          document.file.attach(io: StringIO.new(Base64.decode64(match[:payload])),
                               filename: filename,
                               content_type: content_type)
          document
        end

        def permitted_params
          super.permit(:observed_at, :activity_id, :vegetative_stage_id, :geolocation, :description, pictures: [], plants: %i[id], issues: %i[id])
        end
    end
  end
end
