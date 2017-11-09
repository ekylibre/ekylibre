FactoryGirl.define do
  factory :purchase_nature do
    currency 'EUR'
    nature 'purchase'
    with_accounting true
    journal
  end
end
