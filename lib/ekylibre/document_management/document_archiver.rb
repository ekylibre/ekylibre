# frozen_string_literal: true

module Ekylibre
  module DocumentManagement
    class DocumentArchiver
      class << self
        def build
          new(
            signer: Ekylibre::DocumentManagement::SignatureManager.build
          )
        end
      end

      # @return [Ekylibre::DocumentManagement::SignatureManager]
      attr_reader :signer

      # @param [Ekylibre::DocumentManagement::SignatureManager] signer
      def initialize(signer:)
        @signer = signer
      end

      # @param [Array<byte>] pdf_content
      # @param [DocumentTemplate] template
      # @param [String] key
      # @param [String] name
      # @return [Document]
      def archive_document(pdf_content:, template:, key:, name:)
        document = Document.new(
          nature: template.nature,
          key: key,
          name: name,
          template: template
        )
        document.attach_file(pdf_content, filename: "#{name}.pdf", content_type: 'application/pdf')
        document.save!

        if template.signed
          signer.sign(document: document, user: document.creator)
        end

        document
      end
    end
  end
end
