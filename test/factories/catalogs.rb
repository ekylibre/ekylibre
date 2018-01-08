FactoryGirl.define do
  factory :catalog do
    sequence(:code) { |_n| 'VENTE {n}' }
    sequence(:name) { |_n| 'Vente {n}' }
  end
end
