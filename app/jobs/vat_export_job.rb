class VatExportJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(document_nature, key, state, format, params, user)
    begin
      vat_printer = "#{state.capitalize}VatPrinter".constantize.new(document_nature: document_nature,
                                                                    key: key,
                                                                    state: state,
                                                                    params: params)
      case format
      when 'pdf'
        file_path = vat_printer.run_pdf
        document = Document.find_by(key: key)
      when 'csv'
        csv = vat_printer.run_csv
        filename = "#{state}_#{document_nature}.csv"
        file_path = Ekylibre::Tenant.private_directory.join('tmp', "#{filename}")
        FileUtils.mkdir_p(file_path.dirname)
        File.write(file_path, csv)
        document = Document.create!(nature: document_nature, key: "#{Time.now.to_i}-#{filename}", name: filename, file: File.open(file_path))
      end
      notification = user.notifications.build(valid_generation_notification_params(file_path, key, document.id))
    rescue => error
      Rails.logger.error $!
      Rails.logger.error $!.backtrace.join("\n")
      ExceptionNotifier.notify_exception($!, data: { message: error })
      notification = user.notifications.build(error_generation_notification_params(key, 'vat_register', error.message))
    end
    notification.save
  end
end
