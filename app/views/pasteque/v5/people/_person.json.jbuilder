json.id person.id
json.number person.number
json.key person.full_name
json.dispName person.full_name
json.card person.card if person.respond_to? :card
json.custTaxId person.vat_number
json.discountProfiledId nil
#json.prepaid 0.0
#json.maxDebt 0.0
#json.currDebt 0.0
#json.debtDate Time.now
json.firstName person.first_name
json.lastName person.last_name
json.email person.emails.first.coordinate rescue nil
json.phone1 person.phones.first.coordinate rescue nil
json.phone2 person.phones[1].coordinate rescue nil
json.fax person.faxes.first.coordinate rescue nil
json.addr1 person.mails.first.coordinate rescue nil
json.addr2 person.mails[1].coordinate rescue nil
json.zipCode person.postal_code rescue nil
json.city person.city_name rescue nil
json.region person.region rescue nil
json.country person.country
json.note nil
json.visible person.active
