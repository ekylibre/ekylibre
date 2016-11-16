json.array! @contacts do |contact|
  json.call contact, :last_name, :first_name
  json.addresses do
    unless contact.addresses.order(:canal, :by_default).empty?
      json.array! contact.addresses.order(:canal, :by_default), :canal, :coordinate, :mail_line_1, :mail_line_2, :mail_line_3, :mail_line_4, :mail_line_5, :mail_line_6, :mail_country
    end
  end
end