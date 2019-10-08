FactoryBot.define do
  factory :purchase_invoice do
    association :affair, factory: :purchase_affair
    association :supplier, factory: %i[entity supplier]
    association :nature, factory: :purchase_nature
    amount { 1042.40 }
    pretax_amount { 952.0 }
    currency { 'EUR' }
    tax_payability { 'at_invoicing' }
    invoiced_at { DateTime.new(2018, 1, 1) }
    state { 'invoice' }
  end
end
