class FixedAssetExportJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(document_nature, key, nature, period, user)
    begin
      printer_class_name = "#{nature.camelize}FixedAssetPrinter"
      printer_class = printer_class_name.constantize
      fixed_asset_printer = printer_class.new(document_nature: document_nature, key: key, nature: nature, period: period)
      file_path = fixed_asset_printer.run_pdf
      document = Document.find_by(key: key)
      notification = user.notifications.build(valid_generation_notification_params(file_path, key, document.id))
    rescue => error
      Rails.logger.error $!
      Rails.logger.error $!.backtrace.join("\n")
      ExceptionNotifier.notify_exception($!, data: { message: error })
      notification = user.notifications.build(error_generation_notification_params(key, 'fixed_asset_registry', error.message))
    end
    notification.save
  end
end
