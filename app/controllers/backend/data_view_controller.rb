class Backend::DataViewController < BackendController
  layout false

  respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

end
