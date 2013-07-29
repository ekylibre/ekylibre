class Backend::AggregatorsController < BackendController
  layout false

  respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

  def show
    unless Aggeratio[params[:id]]
      head :not_found
      return
    end
    @aggregator = Aggeratio::Veterinary[params[:id]]
    respond_with @aggregator.build(params)
  end


end
