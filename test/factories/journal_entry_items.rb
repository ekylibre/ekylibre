FactoryBot.define do
  factory :journal_entry_item do
    association :entry, factory: %i[journal_entry with_items]
    account
    absolute_credit { 0 }
    absolute_debit { 0 }
    absolute_pretax_amount { 0 }
    cumulated_absolute_credit { 0 }
    cumulated_absolute_debit { 0 }
    absolute_currency { 'EUR' }
    credit { 0 }
    debit { 0 }
    pretax_amount { 0 }
    balance { 0 }
    currency { 'EUR' }
    real_credit { 0 }
    real_debit { 0 }
    real_pretax_amount { 0 }
    real_balance { 0 }
    real_currency { 'EUR' }
    real_currency_rate { 1.0 }
    state { 'confirmed' }
    sequence(:name) { |i| "JEI #{i}" }
    printed_on { Date.parse('2016-12-01') }
  end
end
