partial_path ||= @record.to_partial_path
record ||= @record.class.name.underscore.downcase.to_sym
json.set! output_name do
  if @record.nil?
    json.null!
  else
    json.partial! "pasteque/v5/#{partial_path}", record => @record, as: record
  end
end
