class Backend::AggregatorsController < BackendController
  # layout false

  respond_to :pdf, :odt, :ods, :docx, :xlsx, :xml, :json, :html, :csv

  def show
    unless klass = Aggeratio[params[:id]]
      head :not_found
      return
    end
    @aggregator = klass.new(params)
    respond_with @aggregator
  end


end
