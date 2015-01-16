partial_path ||= @records.first.to_partial_path rescue "#{output_name.pluralize}/#{output_name.singularize}"
json.status :ok
json.content do
  json.set! output_name.pluralize do
    if @records.empty?
      json.null!
    else
      json.array! @records, partial: "pasteque/v5/#{partial_path}", as: output_name.singularize
    end
  end
end
