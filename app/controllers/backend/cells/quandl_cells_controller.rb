class Backend::Cells::QuandlCellsController < Backend::Cells::BaseController

  def show
    start = Date.today << 12
    finish = start >> 12 - 1
    #params[:threshold] = 183.50
    dataset = params[:dataset] || "CHRIS/LIFFE_EBM4"
    url = "https://www.quandl.com/api/v1/datasets/#{dataset}.json?trim_start=#{start}&trim_end=#{finish}"
    url = "https://www.quandl.com/api/v1/datasets/#{dataset}.json"
    data = JSON.load(open(url))
    if data["errors"].any?
      # TODO Prevent ?
    else
      @data = data.deep_symbolize_keys
    end
  end

end
