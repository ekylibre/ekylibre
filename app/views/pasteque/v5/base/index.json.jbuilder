json.status :ok
json.content do
  if @records.empty?
    json.null!
  else
    json.array! @records, partial: 'content', as: :resource
  end
end
