class Pasteque::V5::CurrenciesController < Pasteque::V5::BaseController

  def index
    availables = SaleNature.pluck :currency
    @records = Nomen::Currencies.list.select{|currency| availables.include? currency.name}
    render template: 'layouts/json/index', locals:{output_name: 'currencies', partial_path: 'currencies/currency', record: :currency}
  end

  def show
    if params[:id] == 'main'
      @record = Preference[:currency]
    else
      @record = Nomen::Currencies.find(params[:id])
      #@record = Nomen::Currencies.all.keep_if{|currency| Nomen::Currencies[currency].number == params[:id]}.first
    end
    render template: 'layouts/json/show', locals:{output_name: 'currency', partial_path: 'currencies/currency', record: :currency}
  end

  private
  def permitted_params
    params.require('currencies').permit('id')
  end
end
