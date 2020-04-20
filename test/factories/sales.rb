FactoryBot.define do
  factory :sale do
    transient {
      items { 1 }
      affair { nil }
    }

    association :nature, factory: :sale_nature
    amount { 5000.0 }
    sequence(:number) { |n| "S00#{n}" }
    downpayment_amount { 0.0 }
    currency { 'EUR' }
    payment_delay { '1 week' }
    state { :draft }
    provider { }

    after(:build) do |sale, eval|
      sale.affair = eval.affair || build(:sale_affair, amount: eval.amount)
      sale.items = build_list(:sale_item, eval.items, sale: sale, amount: eval.amount / eval.items)

      sale.client = sale.affair.client unless sale.client
    end
  end
end
