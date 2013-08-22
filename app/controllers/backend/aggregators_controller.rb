class Backend::AggregatorsController < BackendController
  # layout false

  respond_to :pdf, :odt, :ods, :docx, :xlsx, :xml, :json, :html, :csv


  def index

  end


  def show
    unless klass = Aggeratio[params[:id]]
      head :not_found
      return
    end
    # raise params.inspect
    @aggregator = klass.new(params)
    t3e :name => klass.human_name
    respond_with @aggregator
  end


end
