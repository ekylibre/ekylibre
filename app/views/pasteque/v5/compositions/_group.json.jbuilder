json.id group.id
json.compositionId group.composition_id
json.label groupe.name
begin
  json.hasImage group.picture.present?
rescue
  false
end
json.dispOrder nil
json.choices(group.choices) do |choice|
  json.groupId choice.group_id
  json.productId choice.product_id
end
