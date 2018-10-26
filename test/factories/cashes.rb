FactoryBot.define do
  factory :cash do
    account
    journal
    bank_account_holder_name { 'Dupond' }
    bank_account_key { '' }
    bank_account_number { '' }
    bank_agency_code { '' }
    bank_code { '' }
    bank_identifier_code { 'GHBXFRPP' }
    bank_name { 'GHB' }
    country { 'fr' }
    currency { 'EUR' }
    iban { '' }
    spaced_iban { '' }
    mode { 'iban' }
    nature { 'bank_account' }
    sequence(:name) { |n| "Bank account #{n}" }
  end
end
