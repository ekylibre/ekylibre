partial_path ||= @records.first.to_partial_path rescue "#{output_name.pluralize}/#{output_name.singularize}"
json.set! output_name do
  if @records.empty?
    json.null!
  else
    json.array! @records, partial: "pasteque/v5/#{partial_path}", as: output_name.singularize
  end
end
