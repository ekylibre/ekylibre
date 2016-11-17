json.ignore_nil!
json.array! @contacts do |contact|
  json.call contact, :last_name, :first_name
  json.emails contact.emails, :coordinate unless contact.emails.empty?
  json.phones contact.phones, :coordinate unless contact.phones.empty?
  json.mobiles contact.mobiles, :coordinate unless contact.mobiles.empty?
  json.websites contact.websites, :coordinate unless contact.websites.empty?
  json.mails contact.mails, :mail_line_1, :mail_line_2, :mail_line_3, :mail_line_4, :mail_line_5, :mail_postal_code, :mail_mail_line_6_city, :mail_country  unless contact.emails.empty?
end