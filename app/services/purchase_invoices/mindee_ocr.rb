# frozen_string_literal: true

module PurchaseInvoices
  class MindeeOcr
    # https://platform.mindee.com/mindee/invoices/documentation

    def initialize
      @client = Mindee::Client.new(api_key: ENV['MINDEE_API_KEY'])
    end

    # return a fields based on a document from Ekylibre Document model
    def post_document_and_parse(document)
      # Load a file from disk
      input_source = @client.source_from_path(document.file.path)

      # Parse the file
      response = @client.parse(
        input_source,
        Mindee::Product::Invoice::InvoiceV4
      )

      if response.present? && response.api_request.status == :success
        if response.document.inference.present?
          document.update!(klippa_metadata: response.document.inference.prediction.to_json)
          { status: :success, message: :successfully_document_transformation }
        else
          { status: :warning, message: :stand_by_document_transformation }
        end
      else
        { status: :error, message: response.api_request.errors }
      end
    end

  end
end
