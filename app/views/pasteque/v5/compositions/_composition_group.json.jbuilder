json.id composition_group.id
json.compositionId composition_group.composition_id
json.label composition_groupe.name
json.hasImage composition_group.picture.present? rescue false
json.dispOrder nil
json.choices do
  json.array! composition_group.products, partial: 'pasteque/v5/compositions/group_product', as: :group_product
end
