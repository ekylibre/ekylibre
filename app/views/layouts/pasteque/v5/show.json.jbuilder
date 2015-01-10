partial_path ||= @record.to_partial_path rescue "#{output_name.pluralize}/#{output_name.singularize}"
json.set! output_name.singularize do
  json.foo @record.inspect
  render partial: "pasteque/v5/#{partial_path}", locals:{output_name.singularize.to_sym => @record}
end
