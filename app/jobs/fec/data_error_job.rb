module Fec
  class DataErrorJob < ActiveJob::Base
    queue_as :default
    include Rails.application.routes.url_helpers

    # Check FEC compliance of exported job depending on journal entry compliance field value filled in FEC::Check::JournalEntry
    def perform(financial_year, fiscal_position, user)
      begin
        template = DocumentTemplate.find_by_nature(:fec_data_error)
        dataset_params = { template: template, financial_year: financial_year, fiscal_position: fiscal_position }
        printer = Printers::FecDataErrorPrinter.new(dataset_params)
        entries = printer.compute_dataset

        if entries.empty?
          notification = user.notifications.build(no_fec_data_error_notification)
          return notification.save
        end

        generator = Ekylibre::DocumentManagement::DocumentGenerator.build
        archiver = Ekylibre::DocumentManagement::DocumentArchiver.build

        pdf_data = generator.generate_pdf(template: template, printer: printer)
        document = archiver.archive_document(pdf_content: pdf_data, template: template, key: printer.key, name: printer.document_name)

        notification = user.notifications.build(success_fec_data_error_notification(document.id))
      rescue StandardError => error
        Rails.logger.error error
        Rails.logger.error error.backtrace.join("\n")
        ExceptionNotifier.notify_exception(error, data: { message: error })
        notification = user.notifications.build(error_fec_data_error_notification(error.message))
      end
      notification.save
    end

    private

      def error_fec_data_error_notification(error)
        {
          message: 'error_during_file_generation',
          level: :error,
          interpolations: {
            error_message: error
          }
        }
      end

      def success_fec_data_error_notification(document_id)
        {
          message: 'fec_data_error_file_generated',
          level: :success,
          target_type: 'Document',
          target_id: document_id,
          target_url: backend_document_path(document_id),
          interpolations: {}
        }
      end

      def no_fec_data_error_notification
        {
          message: 'no_fec_data_error',
          level: :information,
          interpolations: {}
        }
      end
  end
end
