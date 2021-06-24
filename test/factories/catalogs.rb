FactoryBot.define do
  factory :catalog do
    currency {'EUR'}
    usage { :sale }
    sequence(:code) { |n| "VENTE #{n}" }
    sequence(:name) { |n| "Catalog #{usage} #{n}"}
  end
end
