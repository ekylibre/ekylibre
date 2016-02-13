module Backend
  class AttachmentsController < Backend::BaseController
    name = controller_name
    record_name = name.to_s.singularize

    def create
      subject = params[:subject_type].constantize.find(params[:subject_id])
      unless params[:attachments]
        head :unprocessable_entity
        return
      end
      @attachment = subject.attachments.create!(params[:attachments].permit!)
      respond_to do |format|
        if @attachment.save(params)
          format.json do
            render json: {
              name: @attachment.name,
              nature: @attachment.nature,
              path: backend_attachment_path(@attachment),
              document: {
                path: backend_document_path(@attachment.document),
                file_path: backend_document_path(@attachment.document, format: :pdf),
                thumbnail_path: backend_document_path(@attachment.document, format: :jpg)
              }
            }, status: :created
          end
        else
          format.json { render json: @attachment.errors.full_messages, status: :unprocessable_entity }
        end
        format.html
      end
    end

    def show
      return unless (@attachment = find_and_check)
      if @attachment.document.file?
        render json: {
          document: {
            file_path: backend_document_path(@attachment.document, format: :pdf)
          },
          name: @attachment.name
        }
      else
        head :not_found
      end
    end

    def destroy
      return unless (@attachment = find_and_check)
      document = @attachment.document
      @attachment.destroy
      document.destroy
      if document.destroyed? && @attachment.destroyed?
        render json: { attachment: 'deleted', status: :ok }
      else
        render json: { message: 'error' }, status: :unprocessable_entity
      end
    end
  end
end
