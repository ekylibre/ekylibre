class Pasteque::V5::TaxesController < Pasteque::V5::BaseController
  def index
    @records = Nomen::TaxNatures.all
    render template: 'layouts/json/index', locals:{output_name: 'tax_categories', partial_path: 'taxes/tax_category', record: :tax_category}
  end

  def show
    @record = Nomen::TaxNatures.all.keep_if{|nature| Nomen::TaxNatures[nature].suffix == params[:id]}.first
    render template: 'layouts/json/show', locals:{output_name: 'tax_category', partial_path: 'taxes/tax_category', record: :tax_category}
  end
end
