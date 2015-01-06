tax_category = Nomen::TaxNatures[tax_category]
taxes = Nomen::Taxes.all.map{|tax| Nomen::Taxes[tax]}.keep_if{|tax|tax.nature == tax_category.name.to_sym}
json.null! unless tax_category.present?
json.id tax_category.name
json.label tax_category.human_name
json.taxes do
  json.array! taxes, partial: 'pasteque/v5/taxes/tax', as: :tax if taxes.any?
end
