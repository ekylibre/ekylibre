FactoryBot.define do
  factory :catalog do
    usage { :sale }
    sequence(:name) { |n| "Catalog #{usage} #{n}"}
  end
end