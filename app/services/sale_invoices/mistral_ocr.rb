# frozen_string_literal: true

module SaleInvoices
  class MistralOcr
    def initialize(vendor)
      if vendor.to_s == 'mistral'
        @client = Clients::Mistral::Ner.new
        @vendor = 'mistral'
      elsif vendor.to_s == 'groq'
        @client = Clients::Mistral::NerGroq.new
        @vendor = 'groq'
      end
    end

    # return a fields based on a document from Ekylibre Document model
    def post_document_and_parse(document)
      # Load a metadata from document
      data = document.file_content_text
      response = @client.extract_metadata(data, :sale_invoice)

      return response[:error] if response[:error].present?

      # Parse the file
      if response.present?
        meta = { @vendor.to_sym => response }
        document.metadata.merge!(meta)
        document.save!
        { status: :success, message: :successfully_document_transformation }
      end
    end

  end
end
