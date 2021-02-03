# frozen_string_literal: true

module Ekylibre
  module DocumentManagement
    # This service is responsible to build an ODT document given a DocumentTemplate and a PrinterBase and is able, using a PdfConverter to convert it in PDF
    class DocumentGenerator
      class << self
        def build
          converter = if Rails.env.test?
                        Ekylibre::DocumentManagement::TestingPdfConverter.build
                      else
                        Ekylibre::DocumentManagement::PdfConverter.build
                      end
          new(
            template_provider: Ekylibre::DocumentManagement::TemplateFileProvider.build,
            pdf_converter: converter
          )
        end
      end

      # @return [TemplateFileProvider]
      attr_reader :template_provider

      # @return [PdfConverter]
      attr_reader :pdf_converter

      def initialize(template_provider:, pdf_converter:)
        @template_provider = template_provider
        @pdf_converter = pdf_converter
      end

      # @param [DocumentTemplate] template
      # @param [PrinterBase] printer
      # @return [Array<byte>]
      def generate_odt(template:, printer:)
        ODFReport::Report
          .new(template_provider.find_by_template(template)) { |r| printer.generate(r) }
          .generate
      end

      # @param [DocumentTemplate] template
      # @param [PrinterBase] printer
      # @return [Array<byte>]
      def generate_pdf(template:, printer:)
        pdf_converter.convert_data(generate_odt(template: template, printer: printer))
      end
    end
  end
end
