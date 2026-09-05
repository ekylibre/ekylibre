json.array! @procedures do |procedure|
  json.partial! 'api/v2/procedures/procedure', procedure: procedure
end
