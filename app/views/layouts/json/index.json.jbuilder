json.set! output_name do
  if @records.empty?
    json.null!
  else
    json.array! @records, partial: "pasteque/v5/#{@records.first.to_partial_path}", as: @records.first.class.name.underscore.downcase.to_sym
  end
end
