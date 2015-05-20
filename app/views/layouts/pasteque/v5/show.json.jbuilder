partial_path ||= @record.to_partial_path rescue "#{output_name.pluralize}/#{output_name.singularize}"
json.status :ok
json.content do
  json.partial! "pasteque/v5/#{partial_path}", output_name.singularize.to_sym => @record
end
