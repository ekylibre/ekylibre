FactoryBot.define do
  factory :label do
    color { FFaker::Color.name }
    name { FFaker::NameFR.name }
  end
end
