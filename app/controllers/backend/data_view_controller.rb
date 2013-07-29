class Backend::DataViewController < BackendController
  layout false

  respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

  def respond_with_view(*args)
    return "DataView::#{controller_name.to_s.singularize.camelcase}".constantize.build(*args)
  end

end
