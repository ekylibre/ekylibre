FactoryBot.define do
  factory :inspection_point do
    net_mass_value { 12 }
    items_count_value { 240 }

    minimal_size_value { 4 }
    maximal_size_value { 13 }
  end
end
