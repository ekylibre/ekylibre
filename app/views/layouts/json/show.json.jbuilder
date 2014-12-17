json.set! output_name do
  if @record.nil?
    json.null!
  else
    json.partial! "pasteque/v5/#{@record.to_partial_path}", @record.class.name.underscore.downcase.to_sym => @record
  end
end
