json.id tax_category.name
json.label tax_category.human_name
references = Nomen::Taxes.list.keep_if{ |tax| tax.nature.to_s == tax_category.name.to_s }
taxes = Tax.where(reference_name: references.map(&:name))
json.taxes do
  json.array! taxes, partial: 'pasteque/v5/taxes/tax', as: :tax 
end
