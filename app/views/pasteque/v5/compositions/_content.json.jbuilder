json.id resource.id
json.groups do
  json.array! resource.groups, partial: 'group', as: :group
end
