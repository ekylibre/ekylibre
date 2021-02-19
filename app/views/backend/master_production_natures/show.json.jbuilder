json.specie resource.specie
json.started_on resource.started_on
json.stopped_on resource.stopped_on
json.start_state_of_production resource.start_state_of_production.values do |ssop|
  json.label ssop.label(locale: locale)
  json.year ssop.year
  json.default ssop.default?
end
json.start resource.start
json.life_duration resource.life_duration
