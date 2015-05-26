class Pasteque::V5::CurrenciesController < Pasteque::V5::BaseController

  def index
    availables = SaleNature.pluck :currency
    @records = Nomen::Currencies.list.select{ |currency| availables.include?(currency.name) }
  end

  def show
    find_and_render params[:id]
  end

  def main
    find_and_render Preference[:currency]
  end

  protected

  def find_and_render(name)
    unless @record = Nomen::Currencies[name]
      render json: {status: "rej", content: "Cannot find currency"}
    end
  end

end
