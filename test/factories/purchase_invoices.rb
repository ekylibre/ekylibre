FactoryGirl.define do
  factory :purchase_invoice do
    amount 1042.40
    pretax_amount 952.0
    currency 'EUR'
    tax_payability 'at_invoicing'
    state 'invoice'
  end
end
