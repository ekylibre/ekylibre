if animals.any?
  json.without_place do
    json.id nil
    json.name :others.tl
    json.animals animals do |animal|
      json.partial! 'animal', animal: animal
    end
  end
end
