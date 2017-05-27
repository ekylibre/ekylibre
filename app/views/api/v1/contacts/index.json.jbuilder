json.ignore_nil!

json.array! []
@items.each do |type, items|
  next if items.empty?
  json.array! items do |contact|
    json.type type
    if contact.is_a?(Hash)
      json.id contact[:item_id]
      next
    end
    json.call(contact, :id)
    json.entity do
      json.call contact, :last_name, :first_name
      [contact.emails, contact.phones, contact.mobiles, contact.websites].each do |addresses|
        next if addresses.empty?
        json.set! addresses.first.canal.to_s, addresses.collect(&:coordinate).compact
      end

      unless contact.mails.empty?
        json.mails contact.mails do |address|
          json.mail_lines address.mail_lines(with_city: false, with_country: false)
          json.postal_code address.mail_postal_code
          json.city address.mail_mail_line_6_city
          json.country address.mail_country
        end
      end

      organization = contact.direct_links.select { |l| (l.entity_role == 'member') && (l.linked_role == 'organization') }.first

      if organization
        json.organization do
          json.name organization.linked.full_name if organization.linked.full_name.present?
          json.post organization.post if organization.post.present?
        end
      end

      json.picture true if contact.picture.file?
    end
  end
end
