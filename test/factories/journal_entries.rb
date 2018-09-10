FactoryBot.define do
  factory :journal_entry do
    journal
    absolute_credit { 0 }
    absolute_debit { 0 }
    absolute_currency { 'EUR' }
    credit { 0 }
    debit { 0 }
    balance { 0 }
    currency { 'EUR' }
    real_credit { 0 }
    real_debit { 0 }
    real_balance { 0 }
    real_currency { 'EUR' }
    real_currency_rate { 1.0 }
    state { 'draft' }
    printed_on { Date.parse('2016-12-01') }

    trait :draft do
    end

    trait :confirmed do
      state { 'confirmed' }
    end

    trait :with_items do
      after(:build) do |entry|
        2.times do
          attributes = attributes_for(:journal_entry_item)
          attributes.update account: create(:account), printed_on: entry.printed_on
          entry.items.build attributes
        end
      end
    end
  end
end
