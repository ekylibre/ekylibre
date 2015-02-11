class Backend::Cells::QuandlCellsController < Backend::Cells::BaseController

  def show
    data = JSON.load(open("https://www.quandl.com/api/v1/datasets/CHRIS/LIFFE_EBM4.json"))
    if data["errors"].any?
    else
      @data = data.deep_symbolize_keys
      puts @data.to_yaml.yellow
    end
  end

end
