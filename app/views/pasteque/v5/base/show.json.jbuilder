json.status :ok
json.content do
  json.partial! 'content', resource: @record
end
