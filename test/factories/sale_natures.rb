FactoryGirl.define do
  factory :sale_nature do
    catalog
    journal
    sequence(:name) { |_n| 'Vente standard {n}' }
    currency 'EUR'

    factory :sale_nature_with_accounting do
      with_accounting true
    end
  end
end
