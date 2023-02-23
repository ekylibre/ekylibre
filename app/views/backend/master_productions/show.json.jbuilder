json.specie resource.specie
json.started_on resource.started_on
json.stopped_on resource.stopped_on
json.start_states resource.start_states do |ss|
  json.label ss.label(locale: locale)
  json.year ss.year
  json.default ss.default?
end
json.cycle resource.cycle
json.started_on_year resource.started_on_year
json.stopped_on_year resource.stopped_on_year
json.life_duration resource.life_duration&.parts&.fetch(:years)
json.usage resource.usage
