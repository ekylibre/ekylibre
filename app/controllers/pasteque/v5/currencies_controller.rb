class Pasteque::V5::CurrenciesController < Pasteque::V5::BaseController

  def index
    availables = SaleNature.pluck :currency
    @records = Nomen::Currencies.list.select{|currency| availables.include? currency.name}
    render template: 'layouts/pasteque/v5/index', locals:{output_name: 'currencies', partial_path: 'currencies/currency', record: :currency}
  end

  def show
    if params[:id] == 'main'
      @record = Nomen::Currencies[Preference[:currency]]
    else
      @record = Nomen::Currencies.find(params[:id])
    end
    if @record.present?
      render partial: 'pasteque/v5/currencies/currency', locals:{currency: @record}
    else
      render status: :not_found, json: nil
    end
  end
end
