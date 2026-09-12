# frozen_string_literal: true

module SaleInvoices
  class MistralOcr
    # Le client d'extraction vivait dans `Clients::Mistral`, retiré de
    # lib/clients : il doit être remplacé par un service Python distinct, qui
    # reste à brancher. On lève à la construction plutôt qu'à l'appel, pour que
    # la panne se voie au plus près de son origine.
    def initialize(vendor)
      raise NotImplementedError.new("Clients::Mistral a été retiré : brancher le service d'extraction avant d'instancier #{self.class}")
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
