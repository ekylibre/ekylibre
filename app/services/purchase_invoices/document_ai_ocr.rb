# frozen_string_literal: true

require "google/cloud/document_ai"

module PurchaseInvoices
  class DocumentAiOcr
    # https://cloud.google.com/document-ai/docs/libraries#client-libraries-install-ruby
    # https://cloud.google.com/ruby/docs/reference/google-cloud-document_ai-v1/latest/Google-Cloud-DocumentAI-V1-DocumentProcessorService-Client-Configuration

    def initialize
      @client = Google::Cloud::DocumentAI.document_processor_service
      ::Google::Cloud::DocumentAI::V1::DocumentProcessorService::Client.configure do |config|
        config.endpoint = ENV['DOC_AI_ENDPOINT']
      end
      @client = Google::Cloud::DocumentAI.document_processor_service
      # Build the resource name from the project.
      @name = @client.processor_path(
        project: ENV['DOC_AI_PROJECT_ID'],
        location: ENV['DOC_AI_REGION_ID'],
        processor: ENV['DOC_AI_PROCESSOR_ID']
      )
    end

    # return a fields based on a document from Ekylibre Document model
    def post_document_and_parse(document)
      file = File.open(document.file.path, 'rb').read
      data_r = File.binread(document.file.path)
      content = Base64.urlsafe_encode64(data_r, padding: false)
      # content = File.binread document.file.path

      # Create request
      request = Google::Cloud::DocumentAI::V1::ProcessRequest.new(
        skip_human_review: true,
        name: @name,
        raw_document: {
          content: content,
          mime_type: document.file_content_type
        }
      )

      # Process document
      response = @client.process_document request
      puts response.inspect.yellow
      if response.present? && response.code == 200
        if response[:result] == "ok"
          document.update!(klippa_metadata: response)
          { status: :success, message: :successfully_document_transformation }
        else
          { status: :warning, message: :stand_by_document_transformation }
        end
      else
        { status: :error, message: :network_error }
      end
    end

  end
end
