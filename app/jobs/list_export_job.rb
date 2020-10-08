class ListExportJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  protected

    def perform(user:, query:, content:, file_name:, format:, file_extension:)
      printer = Printers::ListPrinter.new(file_name: file_name, query: query, content: content)
      data = printer.send("run_#{format}")
      file = data.is_a?(File) ? data : StringIO.new(data)

      document = Document.create!(key: "#{Time.now.to_i}-#{file_name.parameterize}",
                                  name: file_name,
                                  file: file,
                                  file_file_name: "#{file_name.parameterize}.#{file_extension}")

      user.notifications.create!(success_notification_params(document.id))
    rescue StandardError => error
      Rails.logger.error error
      Rails.logger.error error.backtrace.join("\n")
      ExceptionNotifier.notify_exception(error, data: { message: error })
      user.notifications.create!(error_notification_params(error.message))
    end

  private

    def error_notification_params(error)
      {
        message: 'error_during_file_generation',
        level: :error,
        interpolations: {
          error_message: error
        }
      }
    end

    def success_notification_params(document_id)
      {
        message: 'file_generated',
        level: :success,
        target_type: 'Document',
        target_url: backend_document_path(document_id),
        interpolations: {}
      }
    end
end
