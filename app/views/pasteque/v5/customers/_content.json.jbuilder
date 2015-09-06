json.id resource.id.to_s
json.number resource.number
json.key resource.full_name
json.dispName resource.full_name
# json.card resource.card if resource.respond_to? :card
json.card '123456789'
json.custTaxId resource.vat_number
# json.discountProfiledId nil
json.prepaid 0.0
json.maxDebt 0.0
json.currDebt 0.0
# json.debtDate nil
json.firstName resource.first_name
json.lastName resource.last_name
begin
  json.email resource.emails.first.coordinate
rescue
  nil
end
begin
  json.phone1 resource.phones.first.coordinate
rescue
  nil
end
begin
  json.phone2 resource.phones.second.coordinate
rescue
  nil
end
begin
  json.fax resource.faxes.first.coordinate
rescue
  nil
end
begin
  json.addr1 resource.mails.first.coordinate
rescue
  nil
end
begin
  json.addr2 resource.mails.second.coordinate
rescue
  nil
end
begin
  json.zipCode resource.postal_code
rescue
  nil
end
begin
  json.city resource.city_name
rescue
  nil
end
begin
  json.region resource.region
rescue
  nil
end
json.country resource.country
# json.note nil
json.visible resource.active
