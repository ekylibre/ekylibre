partial_path ||= @record.to_partial_path rescue "#{output_name.pluralize}/#{output_name.singularize}"
json.status :ok
json.content [@record], partial: "pasteque/v5/#{partial_path}", as: output_name.singularize
