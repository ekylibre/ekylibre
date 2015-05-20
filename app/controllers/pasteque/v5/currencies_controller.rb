class Pasteque::V5::CurrenciesController < Pasteque::V5::BaseController

  def index
    availables = SaleNature.pluck :currency
    @records = Nomen::Currencies.list.select{|currency| availables.include? currency.name}
    render template: 'layouts/pasteque/v5/index', locals:{output_name: 'currencies', partial_path: 'currencies/currency', record: :currency}
  end

  def show
    find_and_render params[:id]
  end

  def main
    find_and_render Preference[:currency]
  end

  protected

  def find_and_render(name)

    if @record = Nomen::Currencies[name]
      render partial: 'pasteque/v5/currencies/currency', locals: {currency: @record}
    else
      render json: {status: "rej", content: "Cannot find currency"}
    end
  end

end
