partial_path ||= @records.first.to_partial_path
record ||= @records.first.class.name.underscore.downcase.to_sym
json.set! output_name do
  if @records.empty?
    json.null!
  else
    json.array! @records, partial: "pasteque/v5/#{partial_path}", as: record
  end
end
