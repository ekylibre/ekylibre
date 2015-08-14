json.id resource.name
json.label resource.human_name
references = Nomen::Tax.list.keep_if { |tax| tax.nature.to_s == resource.name.to_s }
taxes = Tax.where(reference_name: references.map(&:name))
json.taxes do
  json.array! taxes, partial: 'tax', as: :tax
end
