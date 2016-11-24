json.ignore_nil!

@contacts.each do |type, items|
  next if items.empty?
  json.set! "#{type}" do
    json.array! items do |contact|
      json.call contact, :id, :last_name, :first_name
      [contact.emails, contact.phones, contact.mobiles, contact.websites].each do |addresses|
        next if addresses.empty?
        json.set! "#{addresses.first.canal}", addresses.collect(&:coordinate).compact
      end

      json.mails contact.mails do |address|
        json.mail_lines address.mail_lines(with_city: false, with_country: false)
        json.postal_code address.mail_postal_code
        json.city address.mail_mail_line_6_city
        json.country address.mail_country
      end unless contact.mails.empty?

      organization = contact.direct_links.select { |l| l.entity_role == 'member' and l.linked_role == 'organization' }.first

      if organization
        json.organization do
          json.name organization.linked.full_name unless organization.linked.full_name.blank?
          json.post organization.post unless organization.post.blank?
        end
      end

      json.picture true if contact.picture.file?
    end
  end
end