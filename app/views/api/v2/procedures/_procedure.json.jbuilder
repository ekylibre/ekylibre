json.name procedure.name
json.human_name procedure.human_name
json.position procedure.position
json.deprecated procedure.deprecated?
json.hidden procedure.hidden?
json.categories procedure.categories.map { |c| { name: c.name, human_name: c.human_name } }
json.mandatory_actions procedure.mandatory_actions.map { |a| { name: a.name, human_name: a.human_name } }
json.optional_actions procedure.optional_actions.map { |a| { name: a.name, human_name: a.human_name } }
json.activity_families procedure.activity_families
json.varieties procedure.varieties.map(&:name)
json.parameters procedure.parameters do |parameter|
  json.partial! 'api/v2/procedures/parameter', parameter: parameter
end
