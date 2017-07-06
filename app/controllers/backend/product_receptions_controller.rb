module Backend
  class ProductReceptionsController < Backend::ReceptionsController
    manage_restfully

    respond_to :csv, :ods, :xlsx, :pdf, :odt, :docx, :html, :xml, :json
  end
end
