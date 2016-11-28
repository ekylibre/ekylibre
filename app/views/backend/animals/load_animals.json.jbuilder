json.groups @animal_groups do |group|
  json.call(group, :id, :name)
  json.edit_path edit_backend_animal_group_path(group)

  members = group.members_at(@read_at[:at]).availables(@read_at).order(:name)

  json.places group.places do |place|
    json.call(place, :id, :name)

    json.animals members.contained_by(place).order(:name) do |animal|
      json.partial! 'animal', animal: animal
    end
  end

  # animals without place
  json.partial! 'place', animals: members.select { |animal| animal.container.nil? }
end

json.without_group do
  json.id nil
  json.name :others.tl
  json.partial! 'place', animals: @animals.select { |animal| animal.memberships.empty? }
end
