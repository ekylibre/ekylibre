FactoryBot.define do
  factory :purchase do
    association :affair, factory: :purchase_affair
    association :nature, factory: :purchase_nature
    sequence(:number) { |n| "P00#{n}" }
    amount { 1848.0 }
    pretax_amount { 1545.15 }
    currency { 'EUR' }
    tax_payability { 'at_invoicing' }
    state { 'invoice' }

    after(:build) do |purchase|
      purchase.supplier = purchase.affair.supplier unless purchase.supplier
    end
  end
end
