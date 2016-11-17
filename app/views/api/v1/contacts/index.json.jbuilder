json.ignore_nil!
json.array! @contacts do |contact|
  json.call contact, :last_name, :first_name
  [contact.emails, contact.phones, contact.mobiles, contact.websites].each do |addresses|
    next if addresses.empty?
    json.set! "#{addresses.first.canal}", addresses.collect(&:coordinate).compact
  end

  json.mails contact.mails do |address|
    json.mail_lines address.mail_lines(with_city: false, with_country: false)
    json.postal_code address.mail_postal_code
    json.city address.mail_mail_line_6_city
    json.country address.mail_country
  end

  organization = contact.direct_links.select{|l| l.entity_role == 'member' and l.linked_role == 'organization'}.first

  if organization
    json.organization do
      json.name organization.linked.full_name unless organization.linked.full_name.blank?
      json.post organization.post unless organization.post.blank?
    end
  end

  json.picture contact.id if contact.picture.file?

end