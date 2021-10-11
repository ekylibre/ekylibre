module Fec
  class ExportJob < ActiveJob::Base
    queue_as :default
    include Rails.application.routes.url_helpers

    after_perform do |job|
      format = job.arguments.last
      # If format is XML, there is an additional job which checks structure validations on generated export, so we expect an additional notification
      if format == 'xml'
        raise StandardError.new("An error occured : the FEC document don't exists") if @document.nil?

        fy = job.arguments.first
        user = job.arguments.fourth
        Fec::StructureErrorJob.perform_later(@document, fy, user)
      end
    end

    def perform(financial_year, fiscal_position, interval, user, format)
      interval ||= 'year'
      financial_year.split_into_periods(interval).each_with_index do |period, index|
        begin
          siren = Entity.of_company.siret_number.present? ? Entity.of_company.siren_number : ''

          fy_stopped_on = financial_year.stopped_on.l(format: '%Y%m%d')

          filename = "#{siren}FEC#{fy_stopped_on}"
          filename << "_#{index + 1}" if interval != 'year'

          if format == 'text'
            filename << ".txt"
            fec = FEC::Exporter::CSV.new(financial_year, fiscal_position, period.first, period.last)
          elsif format == 'xml'
            filename << ".xml"
            fec = FEC::Exporter::XML.new(financial_year, fiscal_position, period.first, period.last)
          else
            raise 'Unknown format'
          end

          file_path = Ekylibre::Tenant.private_directory.join('tmp', filename)

          FileUtils.mkdir_p(file_path.dirname)

          File.open(file_path, "wb:UTF-8") do |fout|
            fout.write(fec.generate)
          end

          # If format is Text/CSV, the target notification is a zip containing 2 documents :
          # - A .txt with datas exported with can be used as CSV
          # - A .pdf with a description of the structure the .txt should contain
          if format == 'text'
            fec_description_filename = "fec_description_#{fiscal_position}.pdf"
            fec_description_path = "app/concepts/fec/pdf_description/" + fec_description_filename
            zip_name = "#{Time.now.to_i}FEC#{fy_stopped_on}"
            zipfile_name = Ekylibre::Tenant.private_directory.join('tmp', "#{zip_name}.zip")

            Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
              zipfile.add(fec_description_filename, File.join(fec_description_path))
              zipfile.add(filename, File.join(file_path))
            end

            @document = Document.create!(processable_attachment: false, nature: "exchange_accountancy_file_fr", file: File.open(zipfile_name))
          else
            @document = Document.create!(processable_attachment: false, nature: "exchange_accountancy_file_fr", key: "#{Time.now.to_i}-#{filename}", name: filename, file: File.open(file_path))
          end
          notification = user.notifications.build(success_fec_export_notification(@document.id))
        rescue StandardError => error
          Rails.logger.error error
          Rails.logger.error error.backtrace.join("\n")
          ExceptionNotifier.notify_exception(error, data: { message: error })
          notification = user.notifications.build(error_fec_export_notification(error.message))
        end
        notification.save
      end
    end

    private

      def error_fec_export_notification(error)
        {
          message: 'error_during_file_generation',
          level: :error,
          interpolations: {
            error_message: error
          }
        }
      end

      def success_fec_export_notification(document_id)
        {
          message: 'fec_export_file_generated',
          level: :success,
          target_type: 'Document',
          target_id: document_id,
          target_url: backend_document_path(document_id),
          interpolations: {}
        }
      end
  end
end
