FactoryBot.define do
  factory :matter do
    born_at { DateTime.new(2021, 6, 1) }
    variant factory: :product_nature_variant
  end
end
