# frozen_string_literal: true

module PurchaseInvoices
  class MindeeOcr
    # https://platform.mindee.com/mindee/invoices/documentation
    VENDOR = 'mindee'

    def initialize
      @client = Mindee::Client.new(api_key: ENV['MINDEE_API_KEY'])
    end

    # return a fields based on a document from Ekylibre Document model
    def post_document_and_parse(document)
      # Load a file from disk
      response = document.with_file_path do |path|
        @client.parse(
          @client.source_from_path(path),
          Mindee::Product::Invoice::InvoiceV4
        )
      end

      if response.present? && response.api_request.status == :success
        if response.document.inference.present?
          meta = { VENDOR.to_sym => response.document.inference.prediction }
          document.metadata.merge!(meta)
          document.save!
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
