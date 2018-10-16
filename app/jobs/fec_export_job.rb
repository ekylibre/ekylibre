class FecExportJob < ActiveJob::Base
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(financial_year, fiscal_position, user)
    begin
      filename = "#{Entity.of_company.siren_number}FEC#{financial_year.stopped_on.l(format: '%Y%m%d')}.xml"
      fec = FEC::Exporter::XML.new(financial_year, fiscal_position)
      file_path = Ekylibre::Tenant.private_directory.join('tmp', "#{filename}")
      FileUtils.mkdir_p(file_path.dirname)
      File.write(file_path, fec.generate)
      document = Document.create!(nature: "exchange_accountancy_file_fr", key: "#{Time.now.to_i}-#{filename}", name: filename, file: File.open(file_path))
      notification = user.notifications.build(valid_generation_notification_params(file_path, filename, document.id))
    rescue => error
      notification = user.notifications.build(error_generation_notification_params(filename, 'exchange_accountancy_file_fr', error.message))
    end
    notification.save
  end
end
