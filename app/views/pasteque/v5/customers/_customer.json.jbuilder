json.id customer.id
json.number customer.number
json.key customer.full_name
json.dispName customer.full_name
json.card customer.card if customer.respond_to? :card
json.custTaxId customer.vat_number
json.discountProfiledId nil
#json.prepaid 0.0
#json.maxDebt 0.0
#json.currDebt 0.0
#json.debtDate Time.now
json.firstName customer.first_name
json.lastName customer.last_name
json.email customer.emails.first.coordinate rescue nil
json.phone1 customer.phones.first.coordinate rescue nil
json.phone2 customer.phones[1].coordinate rescue nil
json.fax customer.faxes.first.coordinate rescue nil
json.addr1 customer.mails.first.coordinate rescue nil
json.addr2 customer.mails[1].coordinate rescue nil
json.zipCode customer.postal_code rescue nil
json.city customer.city_name rescue nil
json.region customer.region rescue nil
json.country customer.country
json.note nil
json.visible customer.active
