FactoryBot.define do
  factory :journal_entry do
    transient do
      journal_nature { :various }
    end
    association :journal, :various
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

    sequence(:name) { |i| "Journal Entry DUMMY NAME #{i}" }

    trait :with_items do
      after(:build) do |entry|
        2.times do
          attributes = attributes_for(:journal_entry_item)
          attributes.update account: create(:account), printed_on: entry.printed_on
          entry.items.build attributes
        end
      end
    end

    factory :journal_entry_with_items do
      transient do
        with_credit { 50 }
        with_debit { 50 }
      end

      after(:build) do |entry, evaluator|
        credit = evaluator.with_credit
        debit = evaluator.with_debit
        attributes = attributes_for(:journal_entry_item, real_credit: credit, real_debit: 0)
        attributes.update(account: create(:account), printed_on: entry.printed_on)
        entry.items.build(attributes)

        attributes = attributes_for(:journal_entry_item, real_credit: 0, real_debit: debit)
        attributes.update(account: create(:account), printed_on: entry.printed_on)
        entry.items.build(attributes)
      end
    end

    trait :confirmed do
      state { 'confirmed' }
    end

    trait :draft do
    end

  end
end
