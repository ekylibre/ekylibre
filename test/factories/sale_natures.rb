FactoryBot.define do
  factory :sale_nature do
    catalog
    journal
    sequence(:name) { |n| "Vente standard #{n}" }
    currency { 'EUR' }
  end
end
