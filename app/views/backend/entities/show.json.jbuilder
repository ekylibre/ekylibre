json.extract! resource, :id, :first_name, :last_name, :full_name, :supplier_payment_delay

json.address_id resource.default_mail_address_id
json.address resource.default_mail_address.coordinate if resource.default_mail_address
