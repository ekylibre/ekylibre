FactoryBot.define do
  factory :catalog do
    usage { :sale }
    sequence(:code) { |n| "VENTE #{n}" }
    sequence(:name) { |n| "Catalog #{usage} #{n}"}
  end
end
