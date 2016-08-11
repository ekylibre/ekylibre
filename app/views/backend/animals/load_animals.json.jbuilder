json.groups @animal_groups do |group|
  json.(group, :id, :name)

  members = Animal.members_of(group, @read_at[:at]).order(:name)

  json.places group.places do |place|
    json.(place, :id, :name)

    json.animals members.contained_by(place).order(:name) do |animal|
      json.partial! 'animal', animal: animal
    end
  end

  #animals without place
  json.partial! 'place', animals: members.select{ |animal| animal.container.nil? }

end

json.without_group do
  json.id nil
  json.name :others.tl
  json.partial! 'place', animals: @animals.select{ |animal| animal.memberships.empty? }

end
