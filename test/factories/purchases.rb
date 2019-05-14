FactoryBot.define do
  factory :purchase do
    # needs purchase nature
    # association :affair, factory: :purchase_affair
    association :payee, factory: :entity
    type { "Im here" }
    sequence(:number) { |n| "P00#{n}" }
    amount { 1848.0 }
    pretax_amount { 1545.15 }
    currency { 'EUR' }
    tax_payability { 'at_invoicing' }
    state { 'invoice' }

  end
end
