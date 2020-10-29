FactoryBot.define do
  factory :purchase_nature do
    transient {
      journal_currency { :EUR }
    }

    sequence(:name) { |i| "name #{i}" }
    journal { |journal| journal.association :journal, currency: journal_currency }
  end
end
