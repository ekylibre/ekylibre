FactoryBot.define do
  factory :purchase_order do
    transient do
      item_count { 0 }
    end

    association :supplier, factory: %i[entity supplier]
    association :nature, factory: :purchase_nature
    currency { 'EUR' }

    after :build do |order, options|
      build_list :purchase_item, options.item_count, purchase: order
    end

  end
end
