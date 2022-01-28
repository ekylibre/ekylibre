class ImageDocumentCreationJob < ActiveJob::Base
  queue_as :default

  def perform(document_params, file_params, user_id)
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
  rescue
    user.notifications.create!(document_import_failed_params)
    end
  end

  private

    def document_import_success_params
      {
        message: :document_imported_successfully.tl,
        level: :success,
        target_url: "/backend/documents/#{@document.id}",
        interpolations: { name: @document.name }
      }
    end

    def document_import_failed_params
      {
        message: :document_import_failed.tl,
        level: :error,
        target_url: "/backend/documents",
        interpolations: { name: @document.name }
      }
    end

end
