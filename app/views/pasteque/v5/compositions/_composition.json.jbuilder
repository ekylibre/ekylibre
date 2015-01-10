json.id composition.id
json.groups do
  json.array! composition.groups, partial: 'pasteque/v5/compositions/composition_group', as: :composition_group
end
