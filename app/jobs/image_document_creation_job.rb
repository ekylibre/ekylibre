class ImageDocumentCreationJob < ActiveJob::Base
  queue_as :default

  # rubocop:disable Lint/RescueException
  def perform(document_params, file_params, user_id)
    @name = document_params[:name]
    user = User.find(user_id)
    begin
      attachment_params = {
          filename: file_params[:filename],
          type: file_params[:content_type],
          head: nil,
          tempfile: File.open(file_params[:path])
      }
      document_params[:file] = ActionDispatch::Http::UploadedFile.new(attachment_params)
      @document = Document.new(document_params)
      @document.save!
      user.notifications.create!(document_import_success_params)
    rescue Exception => e
      Rails.logger.error "Exception : #{e}"
      user.notifications.create!(document_import_failed_params)
    end
  end
  # rubocop:enable Lint/RescueException

  private

    def document_import_success_params
      {
        message: :document_imported_successfully.tl,
        level: :success,
        target_url: "/backend/documents/#{@document.id}",
        interpolations: { name: @name }
      }
    end

    def document_import_failed_params
      {
        message: :document_import_failed.tl,
        level: :error,
        target_url: "/backend/documents",
        interpolations: { name: @name }
      }
    end

end
