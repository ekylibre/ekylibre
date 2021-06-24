module Fec
  class StructureErrorJob < ActiveJob::Base
    queue_as :default
    include Rails.application.routes.url_helpers

    # Check structure of exported XML (we need for the document to be already exported to process it) with XSD filed
    # Those files are provided by the government and we use Nokogiri methods to process the validations
    # Then, non human-friendly sentences are translated and transformed into more readeable sentences thanks a forked Gem (XmlErrorsParser)
    def perform(fec_doc, financial_year, user)
      begin
        template = DocumentTemplate.find_by_nature(:fec_structure_error)
        # Exported XML
        fec_parser = Nokogiri::XML(File.read(fec_doc.file.path))
        format = fec_parser.search('comptabilite').attribute('noNamespaceSchemaLocation').value
        raise 'Missing format' if format.nil?

        format_file = Rails.root.join("app/concepts/fec/validators/#{format}")
        # XSD file validator
        xsd = Nokogiri::XML::Schema(File.read(format_file))

        dataset_params = { template: template, financial_year: financial_year, xsd: xsd, fec_parser: fec_parser }
        printer = Printers::FecStructureErrorPrinter.new(dataset_params)

        # Nokogiri does the checks here
        errors = printer.compute_dataset

        if errors.empty?
          notification = user.notifications.build(no_fec_structure_error_notification)
          return notification.save
        end

        generator = Ekylibre::DocumentManagement::DocumentGenerator.build
        archiver = Ekylibre::DocumentManagement::DocumentArchiver.build

        pdf_data = generator.generate_pdf(template: template, printer: printer)
        document = archiver.archive_document(pdf_content: pdf_data, template: template, key: printer.key, name: printer.document_name)

        notification = user.notifications.build(success_fec_structure_error_notification(document.id))
      rescue StandardError => error
        Rails.logger.error error
        Rails.logger.error error.backtrace.join("\n")
        ExceptionNotifier.notify_exception(error, data: { message: error })
        notification = user.notifications.build(error_fec_structure_error_notification(error.message))
      end
      notification.save
    end

    private

      def no_fec_structure_error_notification
        {
          message: 'no_fec_structure_error',
          level: :information,
          interpolations: {}
        }
      end

      def error_fec_structure_error_notification(error)
        {
          message: 'error_during_file_generation',
          level: :error,
          interpolations: {
            error_message: error
          }
        }
      end

      def success_fec_structure_error_notification(document_id)
        {
          message: 'fec_structure_error_file_generated',
          level: :success,
          target_type: 'Document',
          target_id: document_id,
          target_url: backend_document_path(document_id),
          interpolations: {}
        }
      end
  end
end
