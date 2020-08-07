class FecExportJob < ApplicationJob
  queue_as :default
  include Rails.application.routes.url_helpers

  def perform(financial_year, fiscal_position, interval, user, format)
    interval ||= 'year'
    financial_year.split_into_periods(interval).each_with_index do |period, index|
      begin
        siren = Entity.of_company.siret_number.present? ? Entity.of_company.siren_number : ''

        if format == 'text'
          filename = interval == 'year' ? "#{siren}FEC#{financial_year.stopped_on.l(format: '%Y%m%d')}.txt" : "#{siren}FEC#{financial_year.stopped_on.l(format: '%Y%m%d')}_#{index + 1}.txt"
          fec = FEC::Exporter::CSV.new(financial_year, fiscal_position, period.first, period.last)
        end

        if format == 'xml'
          filename = interval == 'year' ? "#{siren}FEC#{financial_year.stopped_on.l(format: '%Y%m%d')}.xml" : "#{siren}FEC#{financial_year.stopped_on.l(format: '%Y%m%d')}_#{index + 1}.xml"
          fec = FEC::Exporter::XML.new(financial_year, fiscal_position, period.first, period.last)
        end

        file_path = Ekylibre::Tenant.private_directory.join('tmp', "#{filename}")
        FileUtils.mkdir_p(file_path.dirname)

        File.open(file_path, "wb:ISO-8859-15") do |fout|
          fout.write(fec.generate)
        end

        document = Document.create!(nature: "exchange_accountancy_file_fr", key: "#{Time.now.to_i}-#{filename}", name: filename, file: File.open(file_path))
        notification = user.notifications.build(valid_generation_notification_params(file_path, filename, document.id))
      rescue => error
        Rails.logger.error $!
        Rails.logger.error $!.backtrace.join("\n")
        ExceptionNotifier.notify_exception($!, data: { message: error })
        notification = user.notifications.build(error_generation_notification_params(filename, 'exchange_accountancy_file_fr', $!.backtrace.join("\n")))
      end
      notification.save
    end
  end
end
