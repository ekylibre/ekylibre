module Backend
  class FinancialYearArchivesController < Backend::BaseController
    def create
      filename = "#{params[:id]}_#{params[:timing]}_unsigned.zip"
      temp_file = Tempfile.new(filename)
      file_path = Ekylibre::Tenant.private_directory.join('attachments', 'documents', 'financial_year_closures', "#{params[:id]}")

      begin
        Zip::OutputStream.open(temp_file) { |zos| }
        Zip::File.open(temp_file.path, Zip::File::CREATE) do |zip|
          Dir[File.join(file_path, "#{params[:id]}_#{params[:timing]}.*")].each do |file|
            zip.add(file.sub("#{file_path}/", ''), file)
          end
        end
        zip_data = File.read(temp_file.path)
        send_data(zip_data, type: 'application/zip', filename: filename)
      ensure
        temp_file.close
        temp_file.unlink
      end
    end
  end
end
