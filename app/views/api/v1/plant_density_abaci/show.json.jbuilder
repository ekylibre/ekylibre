json.call(@plant_density_abacus, :id, :name, :germination_percentage, :sampling_length_unit, :seeding_density_unit, :variety_name, :activity_id)
json.items @plant_density_abacus.items, :id, :seeding_density_value, :plants_count
